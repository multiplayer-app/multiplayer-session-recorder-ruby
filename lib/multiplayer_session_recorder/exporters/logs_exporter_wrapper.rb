# frozen_string_literal: true

require "opentelemetry/sdk"

module Multiplayer
  module SessionRecorder
    module Exporters
    class SessionRecorderLogsExporterWrapper
      def initialize(exporter)
        @exporter = exporter
      end

      def export(logs, timeout: nil)
        # Filter out multiplayer attributes from logs
        filtered_logs = logs.map do |log|
          filtered_log = log.dup
          filtered_log[:attributes] = filter_attributes(log[:attributes])
          filtered_log
        end

        @exporter.export(filtered_logs, timeout: timeout)
      end

      def shutdown(timeout: nil)
        @exporter.shutdown(timeout: timeout)
      end

      def force_flush(timeout: nil)
        @exporter.force_flush(timeout: timeout)
      end

      private

      def filter_attributes(attributes)
        return {} if attributes.nil?

        attributes.each_with_object({}) do |(key, value), filtered|
          unless key.to_s.start_with?(MULTIPLAYER_ATTRIBUTE_PREFIX)
            filtered[key] = value
          end
        end
      end
    end
    end
  end
end
