# frozen_string_literal: true

require 'forwardable'
require_relative '../support/units'
require_relative '../materials/wood'

module FeatherEdge
  module Model
    class Params
      extend Forwardable

      include Support::Units

      MODES = %i[board tiling].freeze
      STAGGER_MODES = %i[none half random].freeze

      attr_reader :mode, :t_top, :angle_deg, :board_length, :course_count,
                  :step, :reveal, :t_bot, :min_joint, :stagger_mode, :seed,
                  :base_offset, :top_offset, :material_name, :warnings, :lod
      attr_reader :material

      def initialize(data = {})
        @mode = (data[:mode] || :board).to_sym
        @t_top = Support::Units.mm(data[:t_top] || 18.0)
        @angle_deg = data[:angle_deg] || 15.0
        @board_length = Support::Units.mm(data[:board_length] || 2400.0)
        @course_count = data[:course_count]&.to_i
        @step = data[:step] ? Support::Units.mm(data[:step]) : nil
        @reveal = data[:reveal] ? Support::Units.mm(data[:reveal]) : nil
        @t_bot = data[:t_bot] ? Support::Units.mm(data[:t_bot]) : nil
        @min_joint = Support::Units.mm(data[:min_joint] || 200.0)
        @stagger_mode = (data[:stagger_mode] || :half).to_sym
        @seed = data[:seed] || rand(10_000)
        @base_offset = Support::Units.mm(data[:base_offset] || 0.0)
        @top_offset = Support::Units.mm(data[:top_offset] || 0.0)
        @material_name = data[:material_name]
        @lod = data[:lod] || 2
        @warnings = []
      end

      def clone_with(overrides = {})
        Params.new(to_h.merge(overrides))
      end

      def ensure_material(model)
        @material ||= begin
          material = material_name && model.materials[material_name]
          material ||= Materials::Wood.new(model).ensure
          @material_name = material.display_name
          material
        end
      end

      def computed?
        !@step.nil?
      end

      def compute_for_face(face, orientation)
        raise ArgumentError, 'Face required' unless face

        bounds = orientation.bounds
        height = bounds.max.y - bounds.min.y
        usable_height = [height - base_offset - top_offset, 0].max
        angle_rad = Support::Units.degrees_to_radians(angle_deg)

        case mode
        when :board
          compute_board_mode(usable_height, angle_rad)
        when :tiling
          compute_tiling_mode(usable_height, angle_rad)
        else
          raise ArgumentError, "Unknown mode #{mode}"
        end

        clamp_t_bot(angle_rad)
        @reveal ||= @step
        @course_count ||= [usable_height / step, 1].max.ceil
        self
      end

      def to_h
        {
          mode: mode,
          t_top: t_top,
          t_bot: t_bot,
          angle_deg: angle_deg,
          board_length: board_length,
          course_count: course_count,
          step: step,
          reveal: reveal,
          min_joint: min_joint,
          stagger_mode: stagger_mode,
          seed: seed,
          base_offset: base_offset,
          top_offset: top_offset,
          material_name: material_name,
          lod: lod
        }
      end

      def angle_rad
        @angle_rad ||= Support::Units.degrees_to_radians(angle_deg)
      end

      def delta_t
        step * Math.tan(angle_rad)
      end

      def height_for_courses
        course_count * step
      end

      def valid?
        warnings.clear
        validate_t_top
        validate_t_bot
        validate_board_length
        warnings.empty?
      end

      def raise_if_invalid!
        return if valid?

        raise ArgumentError, warnings.join(', ')
      end

      private

      attr_writer :material

      def compute_board_mode(usable_height, angle_rad)
        @step ||= default_step(angle_rad)
        @step = clamp_step(@step)
        @t_bot ||= [t_top - step * Math.tan(angle_rad), Support::Units.mm(2)].max
        remainder = usable_height % step
        if remainder.positive? && remainder < step * 0.3
          correction = remainder / course_count_for_height(usable_height)
          @step += correction
        end
      end

      def compute_tiling_mode(usable_height, angle_rad)
        @course_count = [[course_count || 1, 1].max, 600].min
        @step = usable_height / @course_count.to_f
        @reveal = @step
        @t_bot = t_top - step * Math.tan(angle_rad)
      end

      def clamp_t_bot(angle_rad)
        min_bot = Support::Units.mm(2)
        if t_bot < min_bot
          warnings << 't_bot < 2 мм — увеличена автоматически'
          @t_bot = min_bot
        end
        if t_top <= t_bot
          warnings << 't_top должно быть больше t_bot'
        end
      end

      def default_step(angle_rad)
        k = 1.4
        candidate = t_top / Math.tan(angle_rad) * k
        clamp_step(candidate)
      end

      def clamp_step(value)
        min = Support::Units.mm(40)
        max = Support::Units.mm(400)
        value = [[value, min].max, max].min
        value
      end

      def course_count_for_height(usable_height)
        (usable_height / step).ceil
      end

      def validate_t_top
        min = Support::Units.mm(8)
        max = Support::Units.mm(40)
        warnings << 't_top вне диапазона 8–40 мм' unless t_top.between?(min, max)
      end

      def validate_t_bot
        warnings << 't_bot отрицательно' if t_bot.negative?
      end

      def validate_board_length
        min = Support::Units.mm(600)
        warnings << 'Длина доски меньше 600 мм' if board_length < min
      end
    end
  end
end
