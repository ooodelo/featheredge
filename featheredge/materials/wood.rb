# frozen_string_literal: true

module FeatherEdge
  module Materials
    class Wood
      MATERIAL_NAME = 'Cladding — Wood'.freeze

      attr_reader :model

      def initialize(model)
        @model = model
      end

      def ensure
        materials = model.materials
        material = materials[MATERIAL_NAME]
        return material if material

        material = materials.add(MATERIAL_NAME)
        material.color = Sketchup::Color.new(184, 156, 108)
        material.texture = nil
        material
      end
    end
  end
end
