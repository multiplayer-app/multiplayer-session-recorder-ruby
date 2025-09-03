# frozen_string_literal: true

require "opentelemetry-sdk"
require_relative "../type/session_type"

module Multiplayer
  module SessionRecorder
    module Trace
    class SessionRecorderIdGenerator
      include OpenTelemetry::Trace
      
      attr_accessor :session_short_id, :session_type
      attr_reader :generate_long_id, :generate_short_id

      def initialize
        @generate_long_id = self.class.get_id_generator(16)
        @generate_short_id = self.class.get_id_generator(8)
        @session_short_id = ''
        @session_type = Type::SessionType::PLAIN
      end

      def generate_trace_id
        trace_id = @generate_long_id.call

        if @session_short_id && !@session_short_id.empty?
          session_type_prefix = case @session_type
                               when Type::SessionType::CONTINUOUS
                                 MULTIPLAYER_TRACE_CONTINUOUS_DEBUG_PREFIX
                               else
                                 MULTIPLAYER_TRACE_DEBUG_PREFIX
                               end

          prefix = "#{session_type_prefix}#{@session_short_id}"
          session_trace_id = "#{prefix}#{trace_id[prefix.length..-1]}"

          return session_trace_id
        end

        trace_id
      end

      def generate_span_id
        @generate_short_id.call
      end

      def set_session_id(session_short_id, session_type = Type::SessionType::PLAIN)
        @session_short_id = session_short_id
        @session_type = session_type
      end

      private

      def self.get_id_generator(bytes)
        lambda do
          (0...(bytes * 2)).map do |i|
            char_code = rand(16) + 48
            # valid hex characters in the range 48-57 and 97-102
            if char_code >= 58
              char_code += 39
            end
            char_code.chr
          end.join
        end
      end
    end
    end
  end
end
