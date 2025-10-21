# frozen_string_literal: true

require_relative '../support/logging'
require_relative 'orientation'
require_relative 'stripe_tessellator'
require_relative 'board_factory'
require_relative 'course_packer'
require_relative 'intersector'
require_relative 'attribute_store'
require_relative '../materials/wood'

module FeatherEdge
  module Core
    class Generator
      include Support::Logging

      attr_reader :face, :params, :model, :orientation, :tessellator,
                  :board_factory, :course_packer, :intersector, :attribute_store,
                  :entities

      def initialize(face:, params:, orientation: nil, model: Sketchup.active_model, entities: nil)
        @face = face
        @params = params
        @model = model
        @orientation = orientation || Core::Orientation.new(face)
        @tessellator = Core::StripeTessellator.new(orientation)
        @board_factory = Core::BoardFactory.new(model)
        @course_packer = Core::CoursePacker.new(orientation)
        @intersector = Core::Intersector.new(orientation)
        @attribute_store = Core::AttributeStore.new
        @entities = entities || model.active_entities
      end

      def build
        model.start_operation('Создать обшивку FeatherEdge', true)
        group = entities.add_group
        group.name = 'FeatherEdge'
        params.ensure_material(model)

        courses = tessellator.tessellate(face, params)
        logger.info("Generating #{courses.size} courses")
        board_definition = board_factory.fetch_definition(params)

        courses.each do |course|
          course_packer.pack_course(group, board_definition, course, params)
        end

        intersector.trim_to_face(group, face)

        attribute_store.save(group, params, face, orientation)

        group.material = params.material
        group.entities.grep(Sketchup::ComponentInstance).each do |instance|
          instance.material = params.material
        end

        model.commit_operation
        group
      rescue StandardError => e
        logger.error("Failed to generate FeatherEdge cladding: #{e.message}\n#{e.backtrace.join("\n")}")
        model.abort_operation
        raise
      end
    end
  end
end
