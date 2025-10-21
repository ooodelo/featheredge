# frozen_string_literal: true

require_relative '../support/logging'

module FeatherEdge
  module Core
    class CoursePacker
      include Support::Logging

      ORIGIN_POINT = Geom::Point3d.new(0, 0, 0)

      attr_reader :orientation

      def initialize(orientation)
        @orientation = orientation
      end

      def pack_course(group, definition, course, params)
        length = params.board_length
        raise ArgumentError, 'Длина доски должна быть положительной' unless length.positive?

        course.segments.each do |segment|
          pack_segment(group, definition, course, params, segment, length)
        end
      end

      private

      def pack_segment(group, definition, course, params, segment, length)
        left, right = segment
        offset = stagger_offset(course.index, params, length)
        start = left - offset

        u = start
        while u < right + length
          board_start = [u, left].max
          board_end = [u + length, right].min
          if board_end <= left - 1e-4
            u += length
            next
          end
          break if board_start >= right - 1e-4

          actual_length = board_end - board_start
          if actual_length > 1e-3
            transform = orientation.transformation_at(board_start, course.v0)
            scale = actual_length / length
            scale_transform = Geom::Transformation.scaling(ORIGIN_POINT, scale, 1.0, 1.0)
            instance = group.entities.add_instance(definition, transform * scale_transform)
            instance.name = "Board #{course.index + 1}"
            dict = instance.attribute_dictionary('featheredge', true)
            dict['start_u'] = board_start
            dict['end_u'] = board_end
            dict['v0'] = course.v0
            dict['v1'] = course.v1
            dict['course_index'] = course.index
          end

          u += length
        end
      end

      def stagger_offset(index, params, length)
        case params.stagger_mode
        when :none
          0.0
        when :half
          index.odd? ? length / 2.0 : 0.0
        when :random
          random_offset(index, params, length)
        else
          0.0
        end
      end

      def random_offset(index, params, length)
        min_joint = [params.min_joint, length * 0.45].min
        min_joint = length * 0.4 if min_joint >= length
        rng = Random.new(params.seed + index)
        offset = rng.rand * length
        offset = [[offset, min_joint].max, length - min_joint].min
        offset
      end
    end
  end
end
