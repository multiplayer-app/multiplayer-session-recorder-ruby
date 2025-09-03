# frozen_string_literal: true

module Multiplayer
  module SessionRecorder
    module Middleware
      class ResponseMiddleware < Middleware
        def call(env)
          status, headers, response = @app.call(env)

          begin
            current_span = OpenTelemetry::Trace.current_span
            trace_id = current_span.context.trace_id.unpack1("H*")

            headers["x-trace-id"] = trace_id

            masked_headers = @mask_headers.call(headers, current_span)
            response_body = extract_response_body(response)

            if response_body
              masked_body = @mask_body.call(response_body, current_span)
              masked_body = truncate_if_needed(masked_body)

              current_span.set_attribute(ATTR_MULTIPLAYER_HTTP_RESPONSE_HEADERS, masked_headers.to_json)
              current_span.set_attribute(ATTR_MULTIPLAYER_HTTP_RESPONSE_BODY, 
                                       masked_body.is_a?(String) ? masked_body : masked_body.to_json)
            end

            [status, headers, response]
          rescue
            [status, headers, response]
          end
        end
      end
    end
  end
end