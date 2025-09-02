# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/session-recorder"

# Add test directory to load path
$LOAD_PATH.unshift File.expand_path("../test", __FILE__)

# Test that the gem loads correctly
class TestGemLoading < Minitest::Test
  def test_gem_loads_successfully
    assert defined?(Multiplayer::SessionRecorder)
    assert defined?(Multiplayer::SessionRecorder::VERSION)
    refute_nil Multiplayer::SessionRecorder::VERSION
  end

  def test_exporters_module_exists
    assert defined?(Multiplayer::SessionRecorder::Exporters)
  end

  def test_constants_are_loaded
    assert defined?(Multiplayer::SessionRecorder::MULTIPLAYER_TRACE_DEBUG_PREFIX)
    assert_equal 'debdeb', Multiplayer::SessionRecorder::MULTIPLAYER_TRACE_DEBUG_PREFIX
  end
end
