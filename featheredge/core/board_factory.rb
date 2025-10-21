# frozen_string_literal: true

require_relative '../support/logging'
require_relative '../support/units'

module FeatherEdge
  module Core
    class BoardFactory
      include Support::Logging

      attr_reader :model

      def initialize(model)
        @model = model
      end

      def fetch_definition(params)
        name = definition_name(params)
        definition = model.definitions[name]
        return definition if definition

        logger.info("Creating board definition #{name}")
        definition = model.definitions.add(name)
        definition.description = 'FeatherEdge board segment'
        build_geometry(definition, params)
        definition
      end

      private

      def definition_name(params)
        "FeatherEdge Board W#{params.step.round(3)} T#{params.t_top.round(3)} B#{params.t_bot.round(3)}"
      end

      def build_geometry(definition, params)
        entities = definition.entities
        step = params.step
        t_top = params.t_top
        t_bot = params.t_bot
        length = params.board_length

        p0 = Geom::Point3d.new(0, 0, 0)
        p1 = Geom::Point3d.new(0, step, 0)
        p2 = Geom::Point3d.new(0, step, t_top)
        p3 = Geom::Point3d.new(0, 0, t_bot)

        profile = entities.add_face(p0, p1, p2, p3)
        profile.reverse! if profile.normal.z.negative?
        profile.pushpull(length, true)

        soften_edges(definition)
      end

      def soften_edges(definition)
        definition.entities.grep(Sketchup::Edge).each do |edge|
          next unless edge.faces.size == 2

          edge.soft = true
          edge.smooth = true
        end
      end
    end
  end
end
