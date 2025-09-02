# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require_relative '../constants'

module Multiplayer
  module SessionRecorder
    class ApiService
      attr_reader :config

      def initialize
        @config = {
          api_base_url: Multiplayer::SessionRecorder::MULTIPLAYER_BASE_API_URL
        }
      end

      # Initialize the API service
      # @param config [Hash] API service configuration
      # @option config [String] :api_key API key for authentication
      # @option config [String] :api_base_url Base URL for API endpoints
      # @option config [Boolean] :continuous_recording Whether continuous recording is enabled
      def init(config)
        api_base_url = config[:api_base_url] || Multiplayer::SessionRecorder::MULTIPLAYER_BASE_API_URL
        
        @config = {
          **@config,
          **config,
          api_base_url: api_base_url
        }
      end

      # Update the API service configuration
      # @param config [Hash] Partial configuration to update
      def update_configs(config)
        api_base_url = config[:api_base_url] || Multiplayer::SessionRecorder::MULTIPLAYER_BASE_API_URL
        
        @config = {
          **@config,
          **config,
          api_base_url: api_base_url
        }
      end

      # Get the current API base URL
      # @return [String] The current API base URL
      def get_api_base_url
        @config[:api_base_url] || Multiplayer::SessionRecorder::MULTIPLAYER_BASE_API_URL
      end

      # Start a new debug session
      # @param request_body [Hash] Session start request data
      # @return [Hash] Session response
      def start_session(request_body)
        make_request('/debug-sessions/start', 'POST', request_body)
      end

      # Stop an active debug session
      # @param session_id [String] ID of the session to stop
      # @param request_body [Hash] Session stop request data
      # @return [Hash] Response data
      def stop_session(session_id, request_body)
        make_request("/debug-sessions/#{session_id}/stop", 'PATCH', request_body)
      end

      # Cancel an active session
      # @param session_id [String] ID of the session to cancel
      # @return [Hash] Response data
      def cancel_session(session_id)
        make_request("/debug-sessions/#{session_id}/cancel", 'DELETE')
      end

      # Start a new continuous session
      # @param request_body [Hash] Session start request data
      # @return [Hash] Session response
      def start_continuous_session(request_body)
        make_request('/continuous-debug-sessions/start', 'POST', request_body)
      end

      # Save a continuous session
      # @param session_id [String] ID of the session to save
      # @param request_body [Hash] Session save request data
      # @return [Hash] Response data
      def save_continuous_session(session_id, request_body)
        make_request("/continuous-debug-sessions/#{session_id}/save", 'POST', request_body)
      end

      # Stop an active continuous debug session
      # @param session_id [String] ID of the session to stop
      # @return [Hash] Response data
      def stop_continuous_session(session_id)
        make_request("/continuous-debug-sessions/#{session_id}/cancel", 'DELETE')
      end

      # Check if debug session should be started remotely
      # @param request_body [Hash] Session check request data
      # @return [Hash] Response with state information
      def check_remote_session(request_body)
        make_request('/remote-debug-session/check', 'POST', request_body)
      end

      private

      # Make a request to the session API
      # @param path [String] API endpoint path (relative to the base URL)
      # @param method [String] HTTP method (GET, POST, PATCH, etc.)
      # @param body [Hash] Request payload
      # @return [Hash] Response data
      def make_request(path, method, body = nil)
        url = "#{@config[:api_base_url]}/v0/radar#{path}"
        uri = URI(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = case method.upcase
                 when 'GET'
                   Net::HTTP::Get.new(uri)
                 when 'POST'
                   Net::HTTP::Post.new(uri)
                 when 'PATCH'
                   Net::HTTP::Patch.new(uri)
                 when 'DELETE'
                   Net::HTTP::Delete.new(uri)
                 else
                   raise ArgumentError, "Unsupported HTTP method: #{method}"
                 end

        # Set headers
        request['Content-Type'] = 'application/json'
        request['X-Api-Key'] = @config[:api_key] if @config[:api_key]

        # Set body for POST/PATCH requests
        if body && ['POST', 'PATCH'].include?(method.upcase)
          request.body = body.to_json
        end

        # Make the request
        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise RuntimeError, "Network response was not ok: #{response.code} #{response.message}"
        end

        # Return nil for 204 No Content responses
        return nil if response.code == '204'

        # Parse JSON response
        JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError
        raise RuntimeError, 'Invalid JSON response from server'
      rescue StandardError => e
        raise RuntimeError, "Request failed: #{e.message}"
      end
    end
  end
end
