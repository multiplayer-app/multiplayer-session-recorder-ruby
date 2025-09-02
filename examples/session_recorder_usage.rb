# frozen_string_literal: true

require 'session-recorder'

# Example usage of the SessionRecorder class

# 1. Create a session recorder instance
recorder = Multiplayer::SessionRecorder::SessionRecorder.new

# 2. Initialize with configuration
recorder.init(
  api_key: 'your-multiplayer-api-key-here',
  trace_id_generator: Multiplayer::SessionRecorder::Trace::SessionRecorderIdGenerator.new,
  resource_attributes: {
    'service.name' => 'my-ruby-app',
    'service.version' => '1.0.0'
  },
  api_base_url: 'https://api.multiplayer.app' # Optional, uses default if not provided
)

# 3. Start a debug session
begin
  recorder.start(
    Multiplayer::SessionRecorder::Trace::SessionType::PLAIN,
    {
      name: 'User Login Debug Session',
      resource_attributes: {
        'user.id' => '12345',
        'action' => 'login'
      }
    }
  )
  
  puts "Session started with ID: #{recorder.short_session_id}"
  
  # 4. Your application logic here...
  puts "Recording session data..."
  sleep(2) # Simulate some work
  
  # 5. Stop the session
  recorder.stop(
    {
      session_attributes: {
        comment: 'User successfully logged in',
        email: 'user@example.com'
      }
    }
  )
  
  puts "Session stopped successfully"
  
rescue StandardError => e
  puts "Error: #{e.message}"
  
  # 6. Cancel session on error
  recorder.cancel
  puts "Session cancelled due to error"
end

# 7. Example of continuous session
puts "\n--- Continuous Session Example ---"

begin
  recorder.start(
    Multiplayer::SessionRecorder::Trace::SessionType::CONTINUOUS,
    {
      name: 'Continuous Monitoring Session',
      resource_attributes: {
        'monitoring.type' => 'performance',
        'environment' => 'production'
      }
    }
  )
  
  puts "Continuous session started with ID: #{recorder.short_session_id}"
  
  # Simulate some monitoring work
  puts "Monitoring application performance..."
  sleep(3)
  
  # 8. Save the continuous session
  recorder.save(
    {
      name: 'Performance Monitoring Session',
      resource_attributes: {
        'metrics.cpu_usage' => '45%',
        'metrics.memory_usage' => '60%'
      }
    }
  )
  
  puts "Continuous session saved successfully"
  
rescue StandardError => e
  puts "Error in continuous session: #{e.message}"
  recorder.cancel
end

# 9. Example of remote session checking
puts "\n--- Remote Session Check Example ---"

begin
  recorder.check_remote_continuous_session(
    {
      name: 'Remote Check Session',
      resource_attributes: {
        'check.type' => 'automated',
        'timestamp' => Time.now.iso8601
      }
    }
  )
  
  puts "Remote session check completed"
  
rescue StandardError => e
  puts "Error in remote check: #{e.message}"
end

puts "\nSession recorder example completed!"
