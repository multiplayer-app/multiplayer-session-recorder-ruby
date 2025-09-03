#!/usr/bin/env ruby
# frozen_string_literal: true

# Example HTTP server demonstrating SessionRecorder middleware usage
# This example shows how to capture and mask HTTP request/response data
# using the SessionRecorder middleware with OpenTelemetry integration

require 'bundler/setup'
require 'sinatra'
require 'json'
require 'logger'
require 'securerandom'

require_relative 'opentelemetry'

# Configure logging
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# Initialize OpenTelemetry with SessionRecorder
def setup_opentelemetry
  OpenTelemetryConfig.setup(logger)
end

# Custom middleware configuration
class CustomMiddlewareConfig
  def self.mask_body_enabled
    Config::MASK_BODY_ENABLED
  end
  
  def self.mask_headers_enabled
    Config::MASK_HEADERS_ENABLED
  end
  
  def self.capture_body
    Config::CAPTURE_BODY
  end
  
  def self.capture_headers
    Config::CAPTURE_HEADERS
  end
  
  def self.max_payload_size_bytes
    Config::MAX_PAYLOAD_SIZE_BYTES
  end
  
  # Custom body masking function
  def self.custom_mask_body(body)
    return body unless body.is_a?(String)
    
    begin
      parsed = JSON.parse(body)
      # Mask sensitive fields
      if parsed.is_a?(Hash)
        parsed['password'] = '***MASKED***' if parsed.key?('password')
        parsed['token'] = '***MASKED***' if parsed.key?('token')
        parsed['secret'] = '***MASKED***' if parsed.key?('secret')
      end
      parsed.to_json
    rescue JSON::ParserError
      # If not JSON, mask the entire body
      '***MASKED***'
    end
  end
  
  # Custom header masking function
  def self.custom_mask_headers(headers, custom_headers_to_mask = [])
    masked_headers = headers.dup
    
    # Default headers to mask
    default_headers_to_mask = [
      'authorization', 'cookie', 'set-cookie', 'proxy-authorization',
      'x-api-key', 'x-auth-token'
    ]
    
    # Combine default and custom headers to mask
    headers_to_mask = default_headers_to_mask + custom_headers_to_mask
    
    headers_to_mask.each do |header_name|
      if masked_headers.key?(header_name.downcase)
        masked_headers[header_name.downcase] = '***MASKED***'
      end
    end
    
    masked_headers
  end
end

# Configure Sinatra with SessionRecorder middleware
class ExampleServer < Sinatra::Base
  # Enable logging
  enable :logging
  set :logger, logger
  
  # Configure middleware options
  middleware_options = {
    maskBody: method(CustomMiddlewareConfig.custom_mask_body),
    maskHeaders: method(CustomMiddlewareConfig.custom_mask_headers),
    captureHeaders: CustomMiddlewareConfig.capture_headers,
    captureBody: CustomMiddlewareConfig.capture_body,
    isMaskBodyEnabled: CustomMiddlewareConfig.mask_body_enabled,
    isMaskHeadersEnabled: CustomMiddlewareConfig.mask_headers_enabled,
    maxPayloadSizeBytes: CustomMiddlewareConfig.max_payload_size_bytes
  }
  
  # Add SessionRecorder middleware
  use Multiplayer::SessionRecorder::Middleware::RequestMiddleware, middleware_options
  use Multiplayer::SessionRecorder::Middleware::ResponseMiddleware, middleware_options
  
  # Health check endpoint
  get '/health' do
    content_type :json
    { status: 'healthy', timestamp: Time.now.iso8601 }.to_json
  end
  
  # Simple GET endpoint
  get '/api/users' do
    content_type :json
    
    # Simulate some processing time
    sleep(rand(0.1..0.5))
    
    users = [
      { id: 1, name: 'John Doe', email: 'john@example.com' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
      { id: 3, name: 'Bob Johnson', email: 'bob@example.com' }
    ]
    
    # Add trace ID to response headers
    headers['X-Trace-ID'] = OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*")
    
    users.to_json
  end
  
  # POST endpoint with JSON body
  post '/api/users' do
    content_type :json
    
    # Parse request body
    request_body = request.body.read
    user_data = JSON.parse(request_body)
    
    # Simulate user creation
    new_user = {
      id: SecureRandom.uuid,
      name: user_data['name'],
      email: user_data['email'],
      created_at: Time.now.iso8601
    }
    
    # Add trace ID to response headers
    headers['X-Trace-ID'] = OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*")
    
    status 201
    new_user.to_json
  end
  
  # PUT endpoint for updating users
  put '/api/users/:id' do
    content_type :json
    
    user_id = params[:id]
    request_body = request.body.read
    update_data = JSON.parse(request_body)
    
    # Simulate user update
    updated_user = {
      id: user_id,
      name: update_data['name'],
      email: update_data['email'],
      updated_at: Time.now.iso8601
    }
    
    # Add trace ID to response headers
    headers['X-Trace-ID'] = OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*")
    
    updated_user.to_json
  end
  
  # DELETE endpoint
  delete '/api/users/:id' do
    user_id = params[:id]
    
    # Simulate user deletion
    logger.info("Deleting user with ID: #{user_id}")
    
    # Add trace ID to response headers
    headers['X-Trace-ID'] = OpenTelemetry::Trace.current_span.context.trace_id.unpack1("H*")
    
    status 204
  end
  
  # Error handling
  error 400 do
    content_type :json
    { error: 'Bad Request', message: env['sinatra.error'].message }.to_json
  end
  
  error 404 do
    content_type :json
    { error: 'Not Found', message: 'Resource not found' }.to_json
  end
  
  error 500 do
    content_type :json
    { error: 'Internal Server Error', message: 'Something went wrong' }.to_json
  end
end

# Main execution
if __FILE__ == $0
  # Display configuration
  Config.display_config
  
  # Validate configuration
  unless Config.validate
    exit 1
  end
  
  # Setup OpenTelemetry
  setup_opentelemetry
  
  # Start the server
  logger.info("Starting HTTP server on port #{Config::PORT}")
  logger.info("Server will be available at http://localhost:#{Config::PORT}")
  logger.info("")
  logger.info("Available endpoints:")
  logger.info("  GET  /health")
  logger.info("  GET  /api/users")
  logger.info("  POST /api/users")
  logger.info("  PUT  /api/users/:id")
  logger.info("  DELETE /api/users/:id")
  logger.info("")
  logger.info("Test with curl:")
  logger.info("  curl http://localhost:#{Config::PORT}/health")
  logger.info("  curl -X POST http://localhost:#{Config::PORT}/api/users \\")
  logger.info("    -H 'Content-Type: application/json' \\")
  logger.info("    -d '{\"name\":\"Test User\",\"email\":\"test@example.com\"}'")
  
  ExampleServer.run!(
    port: Config::PORT,
    bind: Config::BIND_ADDRESS,
    environment: Config::ENVIRONMENT.to_sym
  )
end
