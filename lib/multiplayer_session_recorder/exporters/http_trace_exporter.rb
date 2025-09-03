# frozen_string_literal: true

require "json"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"

module Multiplayer
  module SessionRecorder
    module Exporters
    class SessionRecorderHttpTraceExporter < OpenTelemetry::Exporter::OTLP::Exporter
      def initialize(config = {})
        endpoint = config[:endpoint] || MULTIPLAYER_OTEL_DEFAULT_TRACES_EXPORTER_HTTP_URL
        api_key = config[:api_key]
        
        raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?
        
        headers = { "Authorization" => api_key }
        headers.merge!(config[:headers]) if config[:headers]
        
        super(endpoint: endpoint, headers: headers)
      end

      def export(spans, timeout: nil)
        # Filter spans by trace ID prefix
        filtered_spans = spans.select do |span|
          trace_id = span.trace_id
          trace_id.start_with?(MULTIPLAYER_TRACE_DEBUG_PREFIX) ||
            trace_id.start_with?(MULTIPLAYER_TRACE_CONTINUOUS_DEBUG_PREFIX)
        end

        return OpenTelemetry::SDK::Trace::Export::SUCCESS if filtered_spans.empty?

        super(filtered_spans, timeout: timeout)
      end
    end
    end
  end
end
