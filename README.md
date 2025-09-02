# Multiplayer Session Recorder

`multiplayer-session-recorder` is a Ruby gem that provides custom OpenTelemetry Protocol (OTLP) exporters and middleware for the Multiplayer platform, enabling seamless integration for tracing data and session recording.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'multiplayer-session-recorder'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install multiplayer-session-recorder
```

### Configuration
For the full opentelemetry configuration example see [example_opentelemetry.rb](example_opentelemetry.rb)

#### Example:

```ruby
## Session Recorder Exporter configuration

MULTIPLAYER_OTLP_KEY = ENV["MULTIPLAYER_OTLP_KEY"]
session_exporter = SessionRecorder::Exporters.create_http_trace_exporter(api_key: MULTIPLAYER_OTLP_KEY)

OpenTelemetry::SDK.configure do |c|
  # Use session recorder exporter in your app
  c.add_span_processor(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(session_exporter))
end
```

### Session Recorder TraceId sampler
```ruby
OpenTelemetry.tracer_provider.sampler = SessionRecorder::Trace::TraceIdRatioBasedSampler.new(1)
```

### Custom Session Recorder traceId generator
```ruby
OpenTelemetry.tracer_provider.id_generator = SessionRecorder::Trace::SessionRecorderIdGenerator.new
```

### Middleware Configuration
```ruby
# Add middleware to your Rails app
config.middleware.insert_before 0, SessionRecorder::Middleware, {
  captureHeaders: true,
  captureBody: true,
  isMaskBodyEnabled: true,
  isMaskHeadersEnabled: true,
  maxPayloadSizeBytes: 500000
}
```

## Features

- **HTTP and gRPC Exporters**: Support for both HTTP and gRPC OTLP endpoints
- **Trace ID Filtering**: Automatic filtering based on debug session prefixes
- **Attribute Filtering**: Wrapper classes to remove multiplayer attributes
- **Configurable Middleware**: Flexible request/response capture and masking
- **Custom Masking**: Support for custom masking functions
- **Session Type Support**: Debug and continuous debug session handling

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

