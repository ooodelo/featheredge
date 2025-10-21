# frozen_string_literal: true

require_relative 'version'
require_relative 'support/logging'
require_relative 'app'
require_relative 'commands'

module FeatherEdge
  extend Support::Logging

  def self.activate
    Support::Logging.logger.info('FeatherEdge extension activated')
    Commands.register!
  end

  activate
end
