# frozen_string_literal: true

module SessionRecorder
  class RequestMiddleware < SessionRecorder::Middleware
    def call(env)
      current_span = OpenTelemetry::Trace.current_span
      trace_id = current_span.context.trace_id.unpack1("H*")
      request = Rack::Request.new(env)

      request_headers = extract_request_headers(env)
      masked_headers = @mask_headers.call(request_headers, current_span)
      current_span.set_attribute(SessionRecorder::ATTR_MULTIPLAYER_HTTP_REQUEST_HEADERS, masked_headers.to_json)

      if request_headers.key?("content-type") && request_headers["content-type"] == "application/json"
        request_body = extract_request_body(request)

        if request_body
          masked_body = @mask_body.call(request_body, current_span)
          masked_body = truncate_if_needed(masked_body)

          current_span.set_attribute(SessionRecorder::ATTR_MULTIPLAYER_HTTP_REQUEST_BODY, 
                                   masked_body.is_a?(String) ? masked_body : masked_body.to_json)
        end
      end

      @app.call(env)
    end
  end
end
