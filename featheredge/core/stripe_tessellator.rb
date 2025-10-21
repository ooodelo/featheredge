# frozen_string_literal: true

require_relative '../support/logging'

module FeatherEdge
  module Core
    class StripeTessellator
      include Support::Logging

      Course = Struct.new(
        :index,
        :v0,
        :v1,
        :outer_loops,
        :hole_loops,
        :segments,
        :u_min,
        :u_max,
        keyword_init: true
      )

      attr_reader :orientation

      def initialize(orientation)
        @orientation = orientation
      end

      def tessellate(face, params)
        bounds = orientation.bounds
        v_min = bounds.min.y + params.base_offset
        v_max = bounds.max.y - params.top_offset
        raise ArgumentError, 'Недостаточная высота для обшивки' if v_max <= v_min

        step = params.step
        v = v_min
        index = 0
        courses = []
        while v < v_max - 1e-6
          v0 = v
          v1 = [v + step, v_max].min
          course = build_course(face, index, v0, v1)
          courses << course if course
          v = v1
          index += 1
        end
        courses
      end

      private

      def build_course(face, index, v0, v1)
        outer_loops = []
        hole_loops = []

        face.loops.each do |loop|
          points = project_loop(loop)
          clipped = clip_polygon(points, v0, v1)
          next if clipped.empty?

          if loop.outer?
            outer_loops.concat(clipped)
          else
            hole_loops.concat(clipped)
          end
        end

        return if outer_loops.empty?

        v_mid = (v0 + v1) / 2.0
        segments = compute_segments(outer_loops, hole_loops, v_mid)
        return if segments.empty?

        u_values = segments.flatten
        Course.new(
          index: index,
          v0: v0,
          v1: v1,
          outer_loops: outer_loops,
          hole_loops: hole_loops,
          segments: segments,
          u_min: u_values.min,
          u_max: u_values.max
        )
      end

      def project_loop(loop)
        loop.vertices.map do |vertex|
          point = vertex.position
          u, v = orientation.uv(point)
          [u, v]
        end
      end

      def clip_polygon(points, v0, v1)
        clipped = [points]
        clipped = clipped.flat_map { |poly| clip_with_line(poly, v0, :bottom) }
        clipped = clipped.flat_map { |poly| clip_with_line(poly, v1, :top) }
        clipped.reject { |poly| poly.length < 3 }
      end

      def clip_with_line(points, value, boundary)
        inside = lambda do |point|
          case boundary
          when :bottom
            point[1] >= value - 1e-6
          when :top
            point[1] <= value + 1e-6
          else
            true
          end
        end

        return [] if points.empty?

        output = []
        prev_point = points.last
        prev_inside = inside.call(prev_point)

        points.each do |point|
          current_inside = inside.call(point)
          if current_inside
            if !prev_inside
              output << intersection(prev_point, point, value)
            end
            output << point
          elsif prev_inside
            output << intersection(prev_point, point, value)
          end
          prev_point = point
          prev_inside = current_inside
        end

        output.empty? ? [] : [output]
      end

      def intersection(p1, p2, value)
        u1, v1 = p1
        u2, v2 = p2
        t = if (v2 - v1).abs < 1e-6
              0.0
            else
              (value - v1) / (v2 - v1)
            end
        u = u1 + (u2 - u1) * t
        v = value
        [u, v]
      end

      def compute_segments(outer_loops, hole_loops, v)
        outer_segments = outer_loops.flat_map { |loop| horizontal_segments(loop, v) }
        hole_segments = hole_loops.flat_map { |loop| horizontal_segments(loop, v) }
        subtract_segments(outer_segments, hole_segments)
      end

      def horizontal_segments(loop, v)
        intersections = []
        loop_points = loop + [loop.first]
        loop_points.each_cons(2) do |p1, p2|
          u1, v1 = p1
          u2, v2 = p2
          next if (v1 - v2).abs < 1e-6

          if between?(v, v1, v2)
            t = (v - v1) / (v2 - v1)
            u = u1 + (u2 - u1) * t
            intersections << u
          end
        end
        intersections.sort!
        segments = []
        intersections.each_slice(2) do |a, b|
          next unless b
          segments << [a, b].sort
        end
        segments
      end

      def between?(v, v1, v2)
        (v >= [v1, v2].min - 1e-6) && (v <= [v1, v2].max + 1e-6)
      end

      def subtract_segments(segments, holes)
        segments = segments.sort_by(&:first)
        holes.each do |hole|
          segments = segments.flat_map { |seg| subtract_segment(seg, hole) }
        end
        segments.reject { |seg| seg[1] - seg[0] < 1e-4 }
      end

      def subtract_segment(segment, hole)
        s1, e1 = segment
        s2, e2 = hole
        return [segment] if e2 <= s1 || s2 >= e1

        pieces = []
        left_end = [s2, e1].min
        pieces << [s1, left_end] if left_end - s1 > 1e-6

        right_start = [e2, s1].max
        pieces << [right_start, e1] if e1 - right_start > 1e-6

        pieces.reject { |seg| seg[1] - seg[0] < 1e-4 }
      end
    end
  end
end
