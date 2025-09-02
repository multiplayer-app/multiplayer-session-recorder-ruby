# config/initializers/opentelemetry.rb

require "opentelemetry-sdk"
require "socket"
require "opentelemetry-exporter-otlp"
require "opentelemetry-api"

require "session-recorder"

SERVICE_NAME = "<service_name>"
SERVICE_VERSION = "<service_version>"
PLATFORM_ENV = "<environment_name>"
MULTIPLAYER_OTLP_KEY = ENV["MULTIPLAYER_OTLP_KEY"]
HOSTNAME = Socket.gethostname

## Session Recorder Exporter configuration
session_exporter = SessionRecorder::Exporters.create_http_trace_exporter(api_key: MULTIPLAYER_OTLP_KEY)

OpenTelemetry::SDK.configure do |c|
  # Set processor for SessionRecorder::Exporters
  c.add_span_processor(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(session_exporter))

  # Set other processors if needed
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(

      # use SessionRecorder::Exporters.create_trace_exporter_wrapper to remove multiplayer attributes
      SessionRecorder::Exporters.create_trace_exporter_wrapper(
        OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
      )
    )
  )
  c.resource = OpenTelemetry::SDK::Resources::Resource.create({
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => SERVICE_NAME,
    OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => SERVICE_VERSION,
    OpenTelemetry::SemanticConventions::Resource::HOST_NAME => HOSTNAME,
    OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT => PLATFORM_ENV,
  })
  c.use_all
end

# Session Recorder TraceId sampler
OpenTelemetry.tracer_provider.sampler = SessionRecorder::Trace::TraceIdRatioBasedSampler.new(1)

# Custom Session Recorder traceId generator
OpenTelemetry.tracer_provider.id_generator = SessionRecorder::Trace::SessionRecorderIdGenerator.new


# Add middlewares in config/application.rb
# Example:
#
# config.middleware.insert_before 0, SessionRecorder::Middleware, {
#   captureHeaders: true,
#   captureBody: true,
#   isMaskBodyEnabled: true,
#   isMaskHeadersEnabled: true,
#   maxPayloadSizeBytes: 500000
# }