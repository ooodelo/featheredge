# frozen_string_literal: true

require_relative '../support/logging'

module FeatherEdge
  module Core
    class Intersector
      include Support::Logging

      attr_reader :orientation

      def initialize(orientation)
        @orientation = orientation
      end

      def trim_to_face(group, face)
        polygon = project_face(face)
        outer_loops = polygon[:outer]
        hole_loops = polygon[:holes]

        group.entities.grep(Sketchup::ComponentInstance).each do |instance|
          data = instance.attribute_dictionary('featheredge')
          next unless data

          start_u = data['start_u']
          end_u = data['end_u']
          v0 = data['v0']
          v1 = data['v1']

          corners = [[start_u, v0], [end_u, v0], [start_u, v1], [end_u, v1]]
          statuses = corners.map { |pt| point_in_polygon?(pt, outer_loops, hole_loops) }
          next if statuses.all?

          if statuses.none?
            logger.info('Removing board completely outside polygon')
            instance.erase!
          else
            logger.warn('Board intersects boundary; deferred precise trim')
          end
        end
      end

      private

      def project_face(face)
        outer = [orientation_loop(face.outer_loop)]
        holes = face.loops.reject(&:outer?).map { |loop| orientation_loop(loop) }
        { outer: outer, holes: holes }
      end

      def orientation_loop(loop)
        loop.vertices.map do |vertex|
          orientation.uv(vertex.position)
        end
      end

      def point_in_polygon?(point, outer_loops, hole_loops)
        inside_outer = outer_loops.any? { |loop| point_in_loop?(point, loop) }
        inside_hole = hole_loops.any? { |loop| point_in_loop?(point, loop) }
        inside_outer && !inside_hole
      end

      def point_in_loop?(point, loop)
        x, y = point
        inside = false
        j = loop.length - 1
        loop.each_with_index do |vertex, i|
          xi, yi = vertex
          xj, yj = loop[j]
          intersects = ((yi > y) != (yj > y)) &&
                       (x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi)
          inside = !inside if intersects
          j = i
        end
        inside
      end
    end
  end
end
