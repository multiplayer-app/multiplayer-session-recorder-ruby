# frozen_string_literal: true

require "opentelemetry-sdk"

module Multiplayer
  module SessionRecorder
    module Trace
    class TraceIdRatioBasedSampler < OpenTelemetry::SDK::Trace::Samplers::TraceIdRatioBased
      def initialize(ratio = 0)
        @ratio = normalize(ratio)
        @upper_bound = (@ratio * 0xffffffff).floor
        super(@ratio)
      end

      def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
        tracestate = OpenTelemetry::Trace.current_span(parent_context).context.tracestate
        
        # Convert trace_id to hex string for comparison
        trace_id_hex = trace_id.unpack1("H*")
        
        # Always sample if trace ID begins with debug prefixes
        if trace_id_hex.start_with?(MULTIPLAYER_TRACE_DEBUG_PREFIX) ||
           trace_id_hex.start_with?(MULTIPLAYER_TRACE_CONTINUOUS_DEBUG_PREFIX)
          return OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE, 
            tracestate: tracestate
          )
        end
        
        # For all other trace IDs, use the provided sampling ratio
        if valid_trace_id?(trace_id_hex) && accumulate(trace_id_hex) < @upper_bound
          OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE, 
            tracestate: tracestate
          )
        else
          OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP, 
            tracestate: tracestate
          )
        end
      end

      def description
        "SessionRecorderTraceIdRatioBasedSampler{ratio=#{@ratio}}"
      end

      private

      def valid_trace_id?(trace_id)
        trace_id.is_a?(String) && trace_id.length == 32 && trace_id =~ /^([0-9a-f]{32})$/i
      end

      def normalize(ratio)
        return 0 unless defined?(ratio) && ratio.is_a?(Numeric)
        return 1 if ratio >= 1
        return 0 if ratio <= 0

        ratio
      end

      def accumulate(trace_id)
        accumulation = 0
        (0...trace_id.length / 8).each do |i|
          pos = i * 8
          part = trace_id[pos, 8].to_i(16)
          accumulation = (accumulation ^ part) & 0xffffffff
        end
        accumulation
      end
    end
    end
  end
end
