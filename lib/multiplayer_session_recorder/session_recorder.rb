# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require_relative 'api_service'
require_relative 'type/session_type'
require_relative 'version'

module Multiplayer
  module SessionRecorder
    class SessionRecorder
      attr_reader :session_state, :session_type, :short_session_id

      def initialize
        @is_initialized = false
        @short_session_id = false
        @trace_id_generator = nil
        @session_type = Type::SessionType::PLAIN
        @session_state = 'STOPPED'
        @api_service = ApiService.new
        @resource_attributes = {}
      end

      # Initialize session recorder with default or custom configurations
      # @param config [Hash] Configuration object
      # @option config [String] :api_key Multiplayer OTLP key
      # @option config [Object] :trace_id_generator Multiplayer compatible trace ID generator
      # @option config [Hash] :resource_attributes Optional resource attributes
      # @option config [Proc, Boolean] :generate_session_short_id_locally Optional session short ID generator
      # @option config [String] :api_base_url Optional base API URL override
      def init(config)
        @resource_attributes = config[:resource_attributes] || {
          Multiplayer::SessionRecorder::ATTR_MULTIPLAYER_SESSION_RECORDER_VERSION => Multiplayer::SessionRecorder::VERSION
        }
        @is_initialized = true

        if config[:generate_session_short_id_locally].respond_to?(:call)
          @session_short_id_generator = config[:generate_session_short_id_locally]
        end

        unless config[:api_key]&.length&.positive?
          raise ArgumentError, 'Api key not provided'
        end

        unless config[:trace_id_generator]&.respond_to?(:set_session_id)
          raise ArgumentError, 'Incompatible trace id generator'
        end

        @trace_id_generator = config[:trace_id_generator]
        @api_service.init(
          api_key: config[:api_key],
          api_base_url: config[:api_base_url]
        )
      end

      # Start a new session
      # @param session_type [String] The type of session to start
      # @param session_payload [Hash] Session metadata
      # @return [void]
      def start(session_type, session_payload = {})
        unless @is_initialized
          raise RuntimeError, 'Configuration not initialized. Call init() before performing any actions.'
        end

        if session_payload[:short_id] && 
           session_payload[:short_id].length != Multiplayer::SessionRecorder::MULTIPLAYER_TRACE_DEBUG_SESSION_SHORT_ID_LENGTH
          raise ArgumentError, 'Invalid short session id'
        end

        session_payload ||= {}

        unless @session_state == 'STOPPED'
          raise RuntimeError, 'Session should be ended before starting new one.'
        end

        @session_type = session_type

        session_payload[:name] ||= "Session on #{get_formatted_date(Time.now)}"
        session_payload[:resourceAttributes] = {
          **@resource_attributes,
          **(session_payload[:resource_attributes] || {})
        }
        # Remove the snake_case version to avoid duplication
        session_payload.delete(:resource_attributes)

        session = if @session_type == Type::SessionType::CONTINUOUS
                   @api_service.start_continuous_session(session_payload)
                 else
                   @api_service.start_session(session_payload)
                 end

        short_id = session&.dig(:shortId) || session&.dig(:short_id)
        unless short_id
          raise RuntimeError, 'Failed to start session'
        end

        @short_session_id = short_id
        @trace_id_generator.set_session_id(@short_session_id, @session_type)
        @session_state = 'STARTED'
      end

      # Save the continuous session (static method)
      # @param reason [String] Optional reason for saving
      # @return [void]
      def self.save(reason = nil)
        # This would call the SDK save method
        # For now, we'll implement it in the instance method
        raise NotImplementedError, 'Static save method not implemented yet'
      end

      # Save the continuous session (instance method)
      # @param session_data [Hash] Session data to save
      # @return [void]
      def save(session_data = {})
        unless @is_initialized
          raise RuntimeError, 'Configuration not initialized. Call init() before performing any actions.'
        end

        if @session_state == 'STOPPED' || !@short_session_id.is_a?(String)
          raise RuntimeError, 'Session should be active or paused'
        end

        unless @session_type == Type::SessionType::CONTINUOUS
          raise RuntimeError, 'Invalid session type'
        end

        session_data[:name] ||= "Session on #{get_formatted_date(Time.now)}"
        @api_service.save_continuous_session(@short_session_id, session_data)
      end

      # Stop the current session with an optional comment
      # @param session_data [Hash] User-provided comment to include in session metadata
      # @return [void]
      def stop(session_data = {})
        unless @is_initialized
          raise RuntimeError, 'Configuration not initialized. Call init() before performing any actions.'
        end

        if @session_state == 'STOPPED' || !@short_session_id.is_a?(String)
          raise RuntimeError, 'Session should be active or paused'
        end

        unless @session_type == Type::SessionType::PLAIN
          raise RuntimeError, 'Invalid session type'
        end

        @api_service.stop_session(@short_session_id, session_data)
      ensure
        @trace_id_generator.set_session_id('')
        @short_session_id = false
        @session_state = 'STOPPED'
      end

      # Cancel the current session
      # @return [void]
      def cancel
        unless @is_initialized
          raise RuntimeError, 'Configuration not initialized. Call init() before performing any actions.'
        end

        if @session_state == 'STOPPED' || !@short_session_id.is_a?(String)
          raise RuntimeError, 'Session should be active or paused'
        end

        if @session_type == Type::SessionType::CONTINUOUS
          @api_service.stop_continuous_session(@short_session_id)
        elsif @session_type == Type::SessionType::PLAIN
          @api_service.cancel_session(@short_session_id)
        end
      ensure
        @trace_id_generator.set_session_id('')
        @short_session_id = false
        @session_state = 'STOPPED'
      end

      # Check if continuous session should be started/stopped automatically
      # @param session_payload [Hash] Session payload for remote check
      # @return [void]
      def check_remote_continuous_session(session_payload = {})
        unless @is_initialized
          raise RuntimeError, 'Configuration not initialized. Call init() before performing any actions.'
        end

        session_payload ||= {}
        session_payload[:resourceAttributes] = {
          **(session_payload[:resource_attributes] || {}),
          **@resource_attributes
        }
        # Remove the snake_case version to avoid duplication
        session_payload.delete(:resource_attributes)

        result = @api_service.check_remote_session(session_payload)
        state = result[:state]

        if state == 'START' && @session_state != 'STARTED'
          start(Type::SessionType::CONTINUOUS, session_payload)
        elsif state == 'STOP' && @session_state != 'STOPPED'
          stop
        end
      end

      private

      def get_formatted_date(time)
        time.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end
end
