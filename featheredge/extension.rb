# frozen_string_literal: true

require 'sketchup'
require 'extensions'

module FeatherEdge
  PLUGIN_ID = 'featheredge'
  EXTENSION_NAME = 'FeatherEdge'
  EXTENSION_DESCRIPTION = 'Parametric bevel siding generator with featheredge boards.'

  unless defined?(EXTENSION)
    path = File.join(__dir__, 'loader.rb')
    EXTENSION = SketchupExtension.new(EXTENSION_NAME, path)
    EXTENSION.description = EXTENSION_DESCRIPTION
    EXTENSION.version = FeatherEdge::VERSION if defined?(FeatherEdge::VERSION)
    EXTENSION.creator = 'LittleCompany'
    Sketchup.register_extension(EXTENSION, true)
  end
end
