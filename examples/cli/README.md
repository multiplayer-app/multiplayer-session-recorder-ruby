# SessionRecorder CLI Example

This example demonstrates how to use the SessionRecorder in a command-line application with OpenTelemetry integration. It's based on the TypeScript example from `@multiplayer-app/session-recorder-node`.

## 🚀 Features

- **Session Management**: Start, manage, and stop debug sessions
- **OpenTelemetry Integration**: Full integration with OpenTelemetry tracing and logging
- **Custom Trace ID Generation**: Uses SessionRecorder's custom trace ID generator
- **Custom Sampling**: Implements trace ID ratio-based sampling
- **Simulated Work**: Demonstrates various types of operations with tracing
- **Graceful Shutdown**: Handles interrupts and cleanup properly

## 📋 Prerequisites

- Ruby 3.0 or higher
- Bundler
- Multiplayer API key (optional for testing)

## 🛠️ Installation

1. **Navigate to the example directory:**
   ```bash
   cd examples/cli/examples
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Set environment variables (optional):**
   ```bash
   export MULTIPLAYER_OTLP_KEY="your-api-key-here"
   export MULTIPLAYER_TRACES_ENDPOINT="https://your-endpoint.com/v1/traces"
   export MULTIPLAYER_LOGS_ENDPOINT="https://your-endpoint.com/v1/logs"
   export ENVIRONMENT="production"
   export COMPONENT_NAME="my-cli-app"
   export COMPONENT_VERSION="2.0.0"
   export DEBUG="true"
   export LOG_LEVEL="DEBUG"
   ```

## 🏃‍♂️ Running the Example

### Basic Usage
```bash
ruby main.rb
```

### With Environment Variables
```bash
MULTIPLAYER_OTLP_KEY="your-key" ENVIRONMENT="staging" ruby main.rb
```

### Debug Mode
```bash
DEBUG=true LOG_LEVEL=DEBUG ruby main.rb
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MULTIPLAYER_OTLP_KEY` | `your-api-key-here` | Multiplayer API key |
| `ENVIRONMENT` | `development` | Environment name |
| `COMPONENT_NAME` | `ruby-cli-example` | Component name |
| `COMPONENT_VERSION` | `1.0.0` | Component version |
| `MULTIPLAYER_TRACES_ENDPOINT` | `nil` | Custom traces endpoint |
| `MULTIPLAYER_LOGS_ENDPOINT` | `nil` | Custom logs endpoint |
| `DEBUG` | `false` | Enable debug mode |
| `LOG_LEVEL` | `INFO` | Logging level |

### Configuration File

The `config.rb` file centralizes all configuration:

```ruby
module Config
  MULTIPLAYER_OTLP_KEY = ENV['MULTIPLAYER_OTLP_KEY'] || 'your-api-key-here'
  ENVIRONMENT = ENV['ENVIRONMENT'] || 'development'
  COMPONENT_NAME = ENV['COMPONENT_NAME'] || 'ruby-cli-example'
  COMPONENT_VERSION = ENV['COMPONENT_VERSION'] || '1.0.0'
  # ... more configuration
end
```

## 📊 OpenTelemetry Integration

### Components Used

1. **Custom Trace ID Generator**: `SessionRecorderIdGenerator`
   - Generates trace IDs with session-specific prefixes
   - Supports both plain and continuous session types

2. **Custom Sampler**: `TraceIdRatioBasedSampler`
   - Always samples traces with debug prefixes
   - Applies ratio-based sampling for other traces

3. **HTTP Exporters**: 
   - `SessionRecorderHttpTraceExporter`
   - `SessionRecorderHttpLogsExporter`

4. **Attribute Wrappers**:
   - Filters out multiplayer-specific attributes
   - Ensures clean trace data

### Configuration

```ruby
# Setup OpenTelemetry
opentelemetry_components = OpenTelemetryConfig.setup

# Initialize SessionRecorder
@session_recorder.init({
  api_key: Config::MULTIPLAYER_OTLP_KEY,
  trace_id_generator: opentelemetry_components[:id_generator],
  resource_attributes: {
    component_name: Config::COMPONENT_NAME,
    component_version: Config::COMPONENT_VERSION,
    environment: Config::ENVIRONMENT
  }
})
```

## 🎬 Session Management

### Starting a Session

```ruby
@session_recorder.start(
  Multiplayer::SessionRecorder::Trace::SessionType::PLAIN,
  {
    name: Config::SESSION_NAME,
    resource_attributes: {
      version: Config::SESSION_VERSION
    }
  }
)
```

### Stopping a Session

```ruby
@session_recorder.stop({
  comment: "CLI application completed successfully",
  metadata: {
    completion_time: Time.now.iso8601,
    work_performed: true
  }
})
```

### Cancelling a Session

```ruby
@session_recorder.cancel
```

## 🔍 Tracing and Observability

### Creating Spans

```ruby
OpenTelemetry::Trace.current_span.in_span("file_operations") do |span|
  span.set_attribute("operation.type", "file_operations")
  span.set_attribute("operation.count", 3)
  
  # Add events
  span.add_event("file.read", { filename: "config.json", size: 1024 })
end
```

### Simulated Operations

The example includes three types of simulated work:

1. **File Operations**: Reading configuration files
2. **Network Calls**: API calls and database queries
3. **Data Processing**: Data transformation and validation

Each operation creates spans with relevant attributes and events.

## 🛡️ Error Handling

### Graceful Shutdown

```ruby
Signal.trap("INT") do
  puts "\n🛑 Received interrupt signal, shutting down gracefully..."
  app.stop_session if app.instance_variable_get(:@running)
  OpenTelemetryConfig.cleanup
  exit(0)
end
```

### Session Cleanup

```ruby
# Try to stop session if it's running
if @running
  @logger.info("🔄 Attempting to stop session...")
  begin
    @session_recorder.cancel
    @logger.info("✅ Session cancelled")
  rescue => cancel_error
    @logger.error("❌ Failed to cancel session: #{cancel_error.message}")
  end
end
```

## 🧪 Testing Different Scenarios

### Test with Real API Key
```bash
MULTIPLAYER_OTLP_KEY="your-real-key" ruby main.rb
```

### Test in Different Environment
```bash
ENVIRONMENT="staging" COMPONENT_NAME="staging-cli" ruby main.rb
```

### Test with Custom Endpoints
```bash
MULTIPLAYER_TRACES_ENDPOINT="https://custom.com/v1/traces" \
MULTIPLAYER_LOGS_ENDPOINT="https://custom.com/v1/logs" \
ruby main.rb
```

### Test Debug Mode
```bash
DEBUG=true LOG_LEVEL=DEBUG ruby main.rb
```

## 🔧 Customization

### Add Custom Work

```ruby
def simulate_custom_work
  @logger.info("🔧 Simulating custom work...")
  
  OpenTelemetry::Trace.current_span.in_span("custom_work") do |span|
    span.set_attribute("operation.type", "custom_work")
    
    # Your custom logic here
    sleep(0.1)
    span.add_event("custom.operation", { detail: "Custom operation completed" })
  end
end
```

### Modify Session Configuration

```ruby
@session_recorder.start(
  Multiplayer::SessionRecorder::Trace::SessionType::CONTINUOUS,  # Change to continuous
  {
    name: "Custom Session Name",
    resource_attributes: {
      version: 2,
      custom_field: "custom_value"
    }
  }
)
```

### Add Custom Resource Attributes

```ruby
@session_recorder.init({
  api_key: Config::MULTIPLAYER_OTLP_KEY,
  trace_id_generator: opentelemetry_components[:id_generator],
  resource_attributes: {
    component_name: Config::COMPONENT_NAME,
    component_version: Config::COMPONENT_VERSION,
    environment: Config::ENVIRONMENT,
    custom_attribute: "custom_value",
    deployment_id: ENV['DEPLOYMENT_ID']
  }
})
```

## 🐛 Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```bash
   bundle install
   ```

2. **Invalid API Key**
   - Check that `MULTIPLAYER_OTLP_KEY` is set correctly
   - Verify the API key has proper permissions

3. **Network Issues**
   - Check firewall settings
   - Verify endpoint URLs are accessible
   - Check SSL certificate validity

4. **OpenTelemetry Configuration Errors**
   - Enable debug mode: `DEBUG=true`
   - Check log level: `LOG_LEVEL=DEBUG`
   - Verify all required gems are installed

### Debug Mode

Enable debug mode to see detailed information:

```bash
DEBUG=true LOG_LEVEL=DEBUG ruby main.rb
```

This will show:
- Detailed OpenTelemetry configuration
- Session initialization details
- Trace ID generation information
- Error stack traces

## 📚 Related Documentation

- [SessionRecorder Main README](../../../README.md)
- [OpenTelemetry Ruby SDK](https://github.com/open-telemetry/opentelemetry-ruby)
- [Multiplayer SessionRecorder](https://multiplayer.app)

## 🤝 Contributing

Feel free to modify this example to suit your needs. Common modifications include:

- Adding more types of simulated work
- Implementing real file operations
- Adding database connectivity
- Implementing real API calls
- Adding configuration file support
- Implementing command-line arguments

## 📄 License

This example is part of the Multiplayer SessionRecorder project and follows the same license terms.
