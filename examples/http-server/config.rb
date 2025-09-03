# frozen_string_literal: true

# Configuration for the HTTP server example
module Config
  # OpenTelemetry API configuration
  MULTIPLAYER_API_KEY = ENV['MULTIPLAYER_API_KEY'] || 'your-api-key-here'
  MULTIPLAYER_TRACES_ENDPOINT = ENV['MULTIPLAYER_TRACES_ENDPOINT'] || 'https://api.multiplayer.com/v1/otlp/traces'
  MULTIPLAYER_LOGS_ENDPOINT = ENV['MULTIPLAYER_LOGS_ENDPOINT'] || 'https://api.multiplayer.com/v1/otlp/logs'
  
  # Server configuration
  PORT = ENV['PORT'] || 3000
  BIND_ADDRESS = ENV['BIND_ADDRESS'] || '0.0.0.0'
  ENVIRONMENT = ENV['ENVIRONMENT'] || 'development'
  
  # Application configuration
  COMPONENT_NAME = ENV['COMPONENT_NAME'] || 'session-recorder-http-server'
  COMPONENT_VERSION = ENV['COMPONENT_VERSION'] || '1.0.0'
  
  # OpenTelemetry configuration
  SAMPLING_RATIO = (ENV['SAMPLING_RATIO'] || '0.1').to_f
  
  # Middleware configuration
  MASK_BODY_ENABLED = ENV['MASK_BODY_ENABLED'] != 'false'
  MASK_HEADERS_ENABLED = ENV['MASK_HEADERS_ENABLED'] != 'false'
  CAPTURE_BODY = ENV['CAPTURE_BODY'] != 'false'
  CAPTURE_HEADERS = ENV['CAPTURE_HEADERS'] != 'false'
  MAX_PAYLOAD_SIZE_BYTES = (ENV['MAX_PAYLOAD_SIZE_BYTES'] || (1024 * 1024)).to_i # 1MB default
  
  # Debug and logging
  DEBUG = ENV['DEBUG'] == 'true'
  LOG_LEVEL = ENV['LOG_LEVEL'] || 'INFO'
end
