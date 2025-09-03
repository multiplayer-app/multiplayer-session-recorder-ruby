# frozen_string_literal: true

# OpenTelemetry configuration for the HTTP server example
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# Add the lib directory to the load path for local development
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))

require 'multiplayer-session-recorder'

module OpenTelemetryConfig
  class << self
    # Initialize OpenTelemetry with SessionRecorder components
    def setup(logger)
      # Create custom trace ID generator
      trace_id_generator = Multiplayer::SessionRecorder::Trace::SessionRecorderIdGenerator.new
      
      # Create custom sampler
      sampler = Multiplayer::SessionRecorder::Trace::TraceIdRatioBasedSampler.new(Config::SAMPLING_RATIO)
      
      # Create HTTP exporters
      http_trace_exporter = Multiplayer::SessionRecorder::Exporters.create_http_trace_exporter(
        api_key: Config::MULTIPLAYER_API_KEY,
        endpoint: Config::MULTIPLAYER_TRACES_ENDPOINT
      )
      
      http_logs_exporter = Multiplayer::SessionRecorder::Exporters.create_http_logs_exporter(
        api_key: Config::MULTIPLAYER_API_KEY,
        endpoint: Config::MULTIPLAYER_LOGS_ENDPOINT
      )
      
      # Create wrappers to filter out multiplayer attributes
      trace_exporter_wrapper = Multiplayer::SessionRecorder::Exporters.create_trace_exporter_wrapper(http_trace_exporter)
      logs_exporter_wrapper = Multiplayer::SessionRecorder::Exporters.create_logs_exporter_wrapper(http_logs_exporter)
      
      # Configure OpenTelemetry
      OpenTelemetry::SDK.configure do |c|
        # Set custom trace ID generator
        c.id_generator = trace_id_generator
        
        # Set custom sampler
        c.sampler = sampler
        
        # Add trace exporters
        c.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(trace_exporter_wrapper)
        )
        
        # Add log processors
        c.add_log_processor(
          OpenTelemetry::SDK::Trace::Export::BatchLogRecordProcessor.new(logs_exporter_wrapper)
        )
      end
      
      logger.info("OpenTelemetry configured with SessionRecorder")
      
      # Return the configured components
      {
        trace_id_generator: trace_id_generator,
        sampler: sampler,
        trace_exporter: trace_exporter_wrapper,
        logs_exporter: logs_exporter_wrapper
      }
    rescue => e
      logger.error("Failed to configure OpenTelemetry: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      raise e
    end
    
    # Cleanup OpenTelemetry resources
    def cleanup
      OpenTelemetry.tracer_provider.shutdown
    end
  end
end
