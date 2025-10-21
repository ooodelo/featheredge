# frozen_string_literal: true

module FeatherEdge
  module Core
    class Orientation
      attr_reader :face, :origin, :u_axis, :v_axis, :normal

      def initialize(face, reference_edge: nil)
        @face = face
        @origin = face.vertices.first.position
        @normal = face.normal
        @u_axis = determine_u_axis(reference_edge)
        @v_axis = (@normal * @u_axis).normalize
        ensure_right_handed!
        build_transforms
      end

      def flip!
        @u_axis = (-@u_axis).normalize
        @v_axis = (@normal * @u_axis).normalize
        build_transforms
      end

      def transformation
        Geom::Transformation.axes(origin, u_axis, v_axis, normal)
      end

      def to_local(point)
        @to_local * point
      end

      def to_world(point)
        @to_world * point
      end

      def uv(point)
        local = to_local(point)
        [local.x, local.y]
      end

      def bounds
        bbox = Geom::BoundingBox.new
        face.vertices.each do |vertex|
          local = to_local(vertex.position)
          bbox.add(Geom::Point3d.new(local.x, local.y, 0))
        end
        bbox
      end

      def to_h
        {
          origin: origin.to_a,
          u_axis: u_axis.to_a,
          v_axis: v_axis.to_a,
          normal: normal.to_a
        }
      end

      def transformation_at(u, v)
        u_offset = u_axis.clone.normalize!
        u_offset.length = u
        v_offset = v_axis.clone.normalize!
        v_offset.length = v
        point = origin.offset(u_offset).offset(v_offset)
        Geom::Transformation.axes(point, u_axis, v_axis, normal)
      end

      private

      def determine_u_axis(reference_edge)
        vector = if reference_edge
                   reference_edge.line[1]
                 else
                   longest_edge_direction
                 end
        vector = vector.clone
        vector.normalize!
        vector
      end

      def longest_edge_direction
        edge = face.outer_loop.edges.max_by { |e| e.length }
        edge.line[1]
      end

      def ensure_right_handed!
        return unless (u_axis * v_axis).dot(normal) < 0

        @v_axis = -@v_axis
      end

      def build_transforms
        @to_world = transformation
        @to_local = @to_world.inverse
      end
    end
  end
end
