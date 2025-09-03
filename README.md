![Description](./docs/img/header-js.png)

<div align="center">
<a href="https://github.com/multiplayer-app/multiplayer-session-recorder-ruby">
  <img src="https://img.shields.io/github/stars/multiplayer-app/multiplayer-session-recorder-ruby?style=social&label=Star&maxAge=2592000" alt="GitHub stars">
</a>
  <a href="https://github.com/multiplayer-app/multiplayer-session-recorder-ruby/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/multiplayer-app/multiplayer-session-recorder-ruby" alt="License">
  </a>
  <a href="https://multiplayer.app">
    <img src="https://img.shields.io/badge/Visit-multiplayer.app-blue" alt="Visit Multiplayer">
  </a>
  
</div>
<div>
  <p align="center">
    <a href="https://x.com/trymultiplayer">
      <img src="https://img.shields.io/badge/Follow%20on%20X-000000?style=for-the-badge&logo=x&logoColor=white" alt="Follow on X" />
    </a>
    <a href="https://www.linkedin.com/company/multiplayer-app/">
      <img src="https://img.shields.io/badge/Follow%20on%20LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="Follow on LinkedIn" />
    </a>
    <a href="https://discord.com/invite/q9K3mDzfrx">
      <img src="https://img.shields.io/badge/Join%20our%20Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join our Discord" />
    </a>
  </p>
</div>

# Multiplayer Full Stack Session Recorder

The Multiplayer Full Stack Session Recorder is a powerful tool that offers deep session replays with insights spanning frontend screens, platform traces, metrics, and logs. It helps your team pinpoint and resolve bugs faster by providing a complete picture of your backend system architecture. No more wasted hours combing through APM data; the Multiplayer Full Stack Session Recorder does it all in one place.

## Install

```bash
gem install multiplayer-session-recorder
```

## Set up backend services

### Route traces and logs to Multiplayer

Multiplayer Full Stack Session Recorder is built on top of OpenTelemetry.

### New to OpenTelemetry?

No problem. You can set it up in a few minutes. If your services don't already use OpenTelemetry, you'll first need to install the OpenTelemetry libraries. Detailed instructions for this can be found in the [OpenTelemetry documentation](https://opentelemetry.io/docs/).

### Already using OpenTelemetry?

You have two primary options for routing your data to Multiplayer:

***Direct Exporter***: This option involves using the Multiplayer Exporter directly within your services. It's a great choice for new applications or startups because it's simple to set up and doesn't require any additional infrastructure. You can configure it to send all session recording data to Multiplayer while optionally sending a sampled subset of data to your existing observability platform.

***OpenTelemetry Collector***: For large, scaled platforms, we recommend using an OpenTelemetry Collector. This approach provides more flexibility by having your services send all telemetry to the collector, which then routes specific session recording data to Multiplayer and other data to your existing observability tools.


### Option 1: Direct Exporter

Send OpenTelemetry data from your services to Multiplayer and optionally other destinations (e.g., OpenTelemetry Collectors, observability platforms, etc.).

This is the quickest way to get started, but consider using an OpenTelemetry Collector (see [Option 2](#option-2-opentelemetry-collector) below) if you're scalling or a have a large platform.

```ruby
require 'multiplayer-session-recorder'
require 'opentelemetry/exporter/otlp'

# set up Multiplayer exporters. Note: GRPC exporters are also available.
# see: Multiplayer::SessionRecorder::Exporters::SessionRecorderGrpcTraceExporter 
# and Multiplayer::SessionRecorder::Exporters::SessionRecorderGrpcLogsExporter
multiplayer_trace_exporter = Multiplayer::SessionRecorder::Exporters::SessionRecorderHttpTraceExporter.new(
  api_key: "MULTIPLAYER_OTLP_KEY" # note: replace with your Multiplayer OTLP key
)
multiplayer_log_exporter = Multiplayer::SessionRecorder::Exporters::SessionRecorderHttpLogsExporter.new(
  api_key: "MULTIPLAYER_OTLP_KEY" # note: replace with your Multiplayer OTLP key
)

# Multiplayer exporter wrappers filter out session recording attributes before passing to provided exporter
trace_exporter = Multiplayer::SessionRecorder::Exporters::SessionRecorderTraceExporterWrapper.new(
  # add any OTLP trace exporter
  OpenTelemetry::Exporter::OTLP::Exporter.new(
    # ...
  )
)
log_exporter = Multiplayer::SessionRecorder::Exporters::SessionRecorderLogsExporterWrapper.new(
  # add any OTLP log exporter
  OpenTelemetry::Exporter::OTLP::LogsExporter.new(
    # ...
  )
)
```

### Option 2: OpenTelemetry Collector

If you're scalling or a have a large platform, consider running a dedicated collector. See the Multiplayer OpenTelemetry collector [repository](https://github.com/multiplayer-app/multiplayer-otlp-collector) which shows how to configure the standard OpenTelemetry Collector to send data to Multiplayer and optional other destinations.

Add standard [OpenTelemetry code](https://opentelemetry.io/docs/languages/ruby/exporters/) to export OTLP data to your collector.

See a basic example below:

```ruby
require 'opentelemetry/exporter/otlp'

trace_exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(
  endpoint: "http://<OTLP_COLLECTOR_URL>/v1/traces",
  headers: {
    # add your headers here
  }
)

log_exporter = OpenTelemetry::Exporter::OTLP::LogsExporter.new(
  endpoint: "http://<OTLP_COLLECTOR_URL>/v1/logs",
  headers: {
    # add your headers here
  }
)
```

### Capturing request/response and header content

In addition to sending traces and logs, you need to capture request and response content. We offer two solutions for this:

***In-Service Code Capture:*** You can use our libraries to capture, serialize, and mask request/response and header content directly within your service code. This is an easy way to get started, especially for new projects, as it requires no extra components in your platform.

***Multiplayer Proxy:*** Alternatively, you can run a [Multiplayer Proxy](https://github.com/multiplayer-app/multiplayer-proxy) to handle this outside of your services. This is ideal for large-scale applications and supports all languages, including those like Java that don't allow for in-service request/response hooks. The proxy can be deployed in various ways, such as an Ingress Proxy, a Sidecar Proxy, or an Embedded Proxy, to best fit your architecture.

### Option 1: In-Service Code Capture

The Multiplayer Session Recorder library provides utilities for capturing request, response and header content. See example below:

```ruby
require 'multiplayer-session-recorder'

# Configure middleware options
middleware_options = {
  maskBody: ->(body) {
    # Custom body masking logic
    return body unless body.is_a?(String)
    
    begin
      parsed = JSON.parse(body)
      if parsed.is_a?(Hash)
        parsed['password'] = '***MASKED***' if parsed.key?('password')
        parsed['token'] = '***MASKED***' if parsed.key?('token')
        parsed['secret'] = '***MASKED***' if parsed.key?('secret')
      end
      parsed.to_json
    rescue JSON::ParserError
      body
    end
  },
  maskHeaders: ->(headers) {
    # List of headers to mask in request/response headers
    masked_headers = headers.dup
    headers_to_mask = ['authorization', 'cookie', 'set-cookie', 'x-api-key']
    
    headers_to_mask.each do |header_name|
      if masked_headers.key?(header_name.downcase)
        masked_headers[header_name.downcase] = '***MASKED***'
      end
    end
    
    masked_headers
  },
  captureHeaders: true,
  captureBody: true,
  isMaskBodyEnabled: true,
  isMaskHeadersEnabled: true,
  # Set the maximum request/response content size (in bytes) that will be captured
  # any request/response content greater than size will be not included in session recordings
  maxPayloadSizeBytes: 500000
}

use Multiplayer::SessionRecorder::Middleware::RequestMiddleware, middleware_options
use Multiplayer::SessionRecorder::Middleware::ResponseMiddleware, middleware_options
```

### Option 2: Multiplayer Proxy

The Multiplayer Proxy enables capturing request/response and header content without changing service code. See instructions at the [Multiplayer Proxy repository](https://github.com/multiplayer-app/multiplayer-proxy).

## Set up CLI app

The Multiplayer Full Stack Session Recorder can be used inside the CLI apps.

The [Multiplayer Time Travel Demo](https://github.com/multiplayer-app/multiplayer-time-travel-platform) includes examples for multiple languages. For Ruby, see the [CLI example](./examples/cli/) in this repository.

See an additional example below.

### Quick start

Use the following code below to initialize and run the session recorder.

Example for Session Recorder initialization relies on [opentelemetry.rb](./examples/cli/opentelemetry.rb) file. Copy that file and put next to quick start code.

```ruby
# IMPORTANT: set up OpenTelemetry
# for an example see ./examples/cli/opentelemetry.rb
# NOTE: for the code below to work copy ./examples/cli/opentelemetry.rb to ./opentelemetry.rb
require_relative 'opentelemetry'
require 'multiplayer-session-recorder'

# Initialize OpenTelemetry with SessionRecorder components
opentelemetry_components = OpenTelemetryConfig.setup

# Initialize SessionRecorder
session_recorder = Multiplayer::SessionRecorder::SessionRecorder.new
session_recorder.init({
  api_key: "MULTIPLAYER_OTLP_KEY", # note: replace with your Multiplayer OTLP key
  trace_id_generator: opentelemetry_components[:id_generator],
  resource_attributes: {
    component_name: "{YOUR_APPLICATION_NAME}",
    component_version: "{YOUR_APPLICATION_VERSION}",
    environment: "{YOUR_APPLICATION_ENVIRONMENT}"
  }
})

session_recorder.start(
  Multiplayer::SessionRecorder::Type::SessionType::PLAIN,
  {
    name: "This is test session",
    resource_attributes: {
      account_id: "687e2c0d3ec8ef6053e9dc97",
      account_name: "Acme Corporation"
    }
  }
)

# do something here

session_recorder.stop({
  sessionAttributes: {
    comment: "Session completed successfully"
  }
})
```

Replace the placeholders with your application’s version, name, environment, and API key.

## License

MIT — see [LICENSE](./LICENSE).
