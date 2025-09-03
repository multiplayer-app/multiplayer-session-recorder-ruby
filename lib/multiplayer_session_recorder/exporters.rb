# frozen_string_literal: true

require_relative "exporters/http_trace_exporter"
require_relative "exporters/http_logs_exporter"
require_relative "exporters/grpc_trace_exporter"
require_relative "exporters/grpc_logs_exporter"
require_relative "exporters/trace_exporter_wrapper"
require_relative "exporters/logs_exporter_wrapper"

module Multiplayer
  module SessionRecorder
    module Exporters
    # Convenience method to create HTTP trace exporter
    def self.create_http_trace_exporter(config = {})
      SessionRecorderHttpTraceExporter.new(config)
    end

    # Convenience method to create HTTP logs exporter
    def self.create_http_logs_exporter(config = {})
      SessionRecorderHttpLogsExporter.new(config)
    end

    # Convenience method to create gRPC trace exporter
    def self.create_grpc_trace_exporter(config = {})
      SessionRecorderGrpcTraceExporter.new(config)
    end

    # Convenience method to create gRPC logs exporter
    def self.create_grpc_logs_exporter(config = {})
      SessionRecorderGrpcLogsExporter.new(config)
    end

    # Convenience method to create trace exporter wrapper
    def self.create_trace_exporter_wrapper(exporter)
      SessionRecorderTraceExporterWrapper.new(exporter)
    end

    # Convenience method to create logs exporter wrapper
    def self.create_logs_exporter_wrapper(exporter)
      SessionRecorderLogsExporterWrapper.new(exporter)
    end
    end
  end
end
