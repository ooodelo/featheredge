# frozen_string_literal: true

require 'logger'
require 'fileutils'
require 'tmpdir'

module FeatherEdge
  module Support
    module Logging
      class ConsoleLogDevice
        def initialize(stream)
          @stream = stream
        end

        def write(message)
          payload = message.to_s
          if @stream.respond_to?(:write)
            @stream.write(payload)
          elsif @stream.respond_to?(:<<)
            @stream << payload
          elsif @stream.respond_to?(:puts)
            payload.each_line { |line| @stream.puts(line.chomp) }
          end
          payload.length
        end

        def close; end

        def flush
          @stream.flush if @stream.respond_to?(:flush)
        end
      end

      def self.logger
        @logger ||= begin
          logger = Logger.new(resolve_log_device)
          logger.level = Logger::INFO
          logger.progname = 'FeatherEdge'
          logger
        end
      end

      def logger
        Logging.logger
      end

      def self.resolve_log_device
        stream = ($stdout if defined?($stdout)) || (STDOUT if defined?(STDOUT))

        if stream
          if stream.respond_to?(:write) && stream.respond_to?(:close)
            return stream
          elsif stream.respond_to?(:write) || stream.respond_to?(:<<) || stream.respond_to?(:puts)
            return ConsoleLogDevice.new(stream)
          end
        end

        ensure_log_file
      end

      def self.ensure_log_file
        base_dir = if defined?(Sketchup) && Sketchup.respond_to?(:temp_dir)
                     File.join(Sketchup.temp_dir, 'FeatherEdge')
                   else
                     File.join(Dir.tmpdir, 'featheredge')
                   end
        FileUtils.mkdir_p(base_dir)
        File.join(base_dir, 'featheredge.log')
      end
    end
  end
end
