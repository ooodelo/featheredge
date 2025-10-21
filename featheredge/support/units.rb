# frozen_string_literal: true

module FeatherEdge
  module Support
    module Units
      extend self

      def mm(value)
        return value.to_f.mm if 0.respond_to?(:mm)

        value.to_f / 25.4
      end

      def degrees_to_radians(value)
        value.to_f * Math::PI / 180.0
      end

      def radians_to_degrees(value)
        value.to_f * 180.0 / Math::PI
      end
    end
  end
end
