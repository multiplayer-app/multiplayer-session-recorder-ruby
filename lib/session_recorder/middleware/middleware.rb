# frozen_string_literal: true

require "json"

module SessionRecorder
  class Middleware
    attr_reader :mask_body, :mask_headers, :capture_headers, :capture_body, 
                :is_mask_body_enabled, :is_mask_headers_enabled, :max_payload_size_bytes

    def initialize(app, options = {})
      @app = app
      
      # Masking functions
      @mask_body = options[:maskBody] || method(:default_mask_body)
      @mask_headers = options[:maskHeaders] || method(:default_mask_headers)
      
      # Capture flags
      @capture_headers = options.fetch(:captureHeaders, true)
      @capture_body = options.fetch(:captureBody, true)
      
      # Masking flags
      @is_mask_body_enabled = options.fetch(:isMaskBodyEnabled, true)
      @is_mask_headers_enabled = options.fetch(:isMaskHeadersEnabled, true)
      
      # Payload size limit
      @max_payload_size_bytes = options[:maxPayloadSizeBytes] || SessionRecorder::MULTIPLAYER_MAX_HTTP_REQUEST_RESPONSE_SIZE
    end

    protected

    def default_mask_body(value)
      return SessionRecorder::MASK_PLACEHOLDER unless @is_mask_body_enabled
      
      payload_json = begin
                       JSON.parse(value)
                     rescue JSON::ParserError
                       value
                     end

      masked_data = mask_primitives(payload_json)

      unless masked_data.is_a?(String)
        masked_data = masked_data.to_json
      end

      masked_data
    end

    def default_mask_headers(headers, custom_header_names_to_mask = [])
      return headers unless @is_mask_headers_enabled
      
      default_header_names_to_mask = ["set-cookie", "cookie", "authorization", "proxy-authorization"]
      masked_headers = headers.dup
      headers_to_mask = default_header_names_to_mask + custom_header_names_to_mask

      headers_to_mask.each do |header_name|
        masked_headers[header_name] = SessionRecorder::MASK_PLACEHOLDER if masked_headers.key?(header_name)
      end

      masked_headers
    end

    def mask_primitives(input, current_depth = 0)
      return SessionRecorder::MASK_PLACEHOLDER if current_depth >= SessionRecorder::MAX_MASK_DEPTH

      case input
      when Hash
        input.transform_values { |value| mask_primitives(value, current_depth + 1) }
      when Array
        input.map { |value| mask_primitives(value, current_depth + 1) }
      when String, Numeric, TrueClass, FalseClass, NilClass, Symbol
        SessionRecorder::MASK_PLACEHOLDER
      else
        input
      end
    end

    # Extracts request headers from the Rack environment
    def extract_request_headers(env)
      return {} unless @capture_headers
      
      env.select { |k, _| k.start_with?("HTTP_") }
         .transform_keys { |k| k.sub(/^HTTP_/, "").split("_").map(&:downcase).join("-") }
    end

    # Reads the request body safely
    def extract_request_body(request)
      return nil unless @capture_body
      
      body = request.body.read
      request.body.rewind # Rewind the stream for downstream middlewares
      body
    end

    # Reads the response body safely
    def extract_response_body(response)
      return nil unless @capture_body
      
      body = []
      response.each { |part| body << part }
      body.join
    end

    # Truncates payload if maxPayloadSizeBytes is set
    def truncate_if_needed(data)
      return data unless data.to_s.size > @max_payload_size_bytes
      "#{data[0...@max_payload_size_bytes]}...[TRUNCATED]"
    end
  end
end
