# frozen_string_literal: true

require "json"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"

module Multiplayer
  module SessionRecorder
    module Exporters
    class SessionRecorderGrpcLogsExporter < OpenTelemetry::Exporter::OTLP::Exporter
      def initialize(config = {})
        endpoint = config[:endpoint] || MULTIPLAYER_OTEL_DEFAULT_LOGS_EXPORTER_GRPC_URL
        api_key = config[:api_key]
        
        raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?
        
        headers = { "Authorization" => api_key }
        headers.merge!(config[:headers]) if config[:headers]
        
        super(endpoint: endpoint, headers: headers)
      end

      def export(logs, timeout: nil)
        # Filter logs by trace ID prefix
        filtered_logs = logs.select do |log|
          trace_id = log.trace_id
          trace_id.start_with?(MULTIPLAYER_TRACE_DEBUG_PREFIX) ||
            trace_id.start_with?(MULTIPLAYER_TRACE_CONTINUOUS_DEBUG_PREFIX)
        end

        return OpenTelemetry::SDK::Trace::Export::SUCCESS if filtered_logs.empty?

        super(filtered_logs, timeout: timeout)
      end
    end
    end
  end
end
