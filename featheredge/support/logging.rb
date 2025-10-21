# frozen_string_literal: true

require 'logger'

module FeatherEdge
  module Support
    module Logging
      def self.logger
        @logger ||= begin
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger.progname = 'FeatherEdge'
          logger
        end
      end

      def logger
        Logging.logger
      end
    end
  end
end
