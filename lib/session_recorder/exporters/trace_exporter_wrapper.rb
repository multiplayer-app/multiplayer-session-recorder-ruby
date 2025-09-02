# frozen_string_literal: true

require "opentelemetry/sdk"

module SessionRecorder
  module Exporters
    class SessionRecorderTraceExporterWrapper
      def initialize(exporter)
        @exporter = exporter
      end

      def export(spans, timeout: nil)
        # Filter out multiplayer attributes from spans
        filtered_spans = spans.map do |span|
          filtered_span = span.dup
          filtered_span[:attributes] = filter_attributes(span[:attributes])
          filtered_span
        end

        @exporter.export(filtered_spans, timeout: timeout)
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
          unless key.to_s.start_with?(SessionRecorder::MULTIPLAYER_ATTRIBUTE_PREFIX)
            filtered[key] = value
          end
        end
      end
    end
  end
end
