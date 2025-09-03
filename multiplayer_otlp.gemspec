require_relative "lib/multiplayer_session_recorder/version"

Gem::Specification.new do |s|
    s.name        = "multiplayer-session-recorder"
    s.version     = Multiplayer::SessionRecorder::VERSION
    s.summary     = "Multiplayer Fullstack Session Recorder"
    s.files = Dir["lib/**/*.rb"]
    s.require_paths = ["lib"]

    s.authors     = ["Multiplayer Inc."]
    s.homepage    =
      "https://rubygems.org/gems/multiplayer_session_recorder"
    s.license       = "MIT"
    s.required_ruby_version = '>= 3.0'

    s.add_dependency "opentelemetry-sdk", "~> 1.6"
    s.add_dependency "opentelemetry-exporter-otlp", "~> 0.29.1"
end
