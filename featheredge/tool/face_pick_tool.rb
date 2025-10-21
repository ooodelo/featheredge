# frozen_string_literal: true

require_relative '../support/logging'
require_relative '../core/orientation'
require_relative '../core/stripe_tessellator'
require_relative '../core/generator'
require_relative '../model/params'

module FeatherEdge
  module Tool
    class FacePickTool
      include Support::Logging

      attr_accessor :mode
      attr_reader :lod

      ESCAPE_KEY = defined?(Sketchup::VK_ESCAPE) ? Sketchup::VK_ESCAPE : 27
      TAB_KEY = defined?(Sketchup::VK_TAB) ? Sketchup::VK_TAB : 9

      FALLBACK_CURSOR_ID = if defined?(Sketchup::Cursor::ARROW)
                             Sketchup::Cursor::ARROW
                           else
                             0
                           end

      CURSOR_IMAGE_PATH = File.expand_path('../assets/face_pick_cursor_blank.png', __dir__)
      CURSOR_HOTSPOT = [0, 0].freeze
      CURSOR_PIXEL_SIZE = 18

      def initialize(dialog:)
        @dialog = dialog
        @dialog.tool = self if @dialog.respond_to?(:tool=)
        reset_state
        @lod = 1
        @mode = :create
        @cursor_screen_point = nil
      end

      def activate
        reset_state
        Sketchup.status_text = 'Выберите плоскую грань для обшивки FeatherEdge.'
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        view.invalidate
      end

      def onCancel(reason, view)
        reset_state
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        store_cursor_screen_point(x, y)
        ph = view.pick_helper
        ph.do_pick(x, y)
        entity = ph.best_picked
        face = entity if entity.is_a?(Sketchup::Face)
        if face && face.valid? && planar?(face)
          update_hover_face(face)
        else
          clear_hover_face
        end
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        return unless @hover_face

        store_cursor_screen_point(x, y)
        select_face(@hover_face)
        view.invalidate
      end

      def onKeyDown(key, repeat, flags, view)
        case key
        when ESCAPE_KEY
          reset_state
          view.invalidate
        when 'R'.ord
          flip_direction!
          view.invalidate
        when TAB_KEY
          toggle_direction_mode
          view.invalidate
        end
        false
      end

      def getCursorID
        FALLBACK_CURSOR_ID
      end

      def onSetCursor
        id = self.class.transparent_cursor_id || FALLBACK_CURSOR_ID
        UI.set_cursor(id) if UI.respond_to?(:set_cursor)
        true
      end

      def draw(view)
        draw_preview(view)
        draw_cursor_overlay(view)
      end

      def flip_direction!
        return unless @orientation

        @orientation.flip!
        if @selected_face
          @dialog.set_context(face: @selected_face, orientation: @orientation)
          update_preview(@current_params) if @current_params
        end
      end

      def toggle_lod!
        @lod = (@lod + 1) % 3
      end

      def toggle_direction_mode
        # placeholder for manual direction selection via edge pick in future revisions
        UI.messagebox('Ручной выбор направления пока недоступен в этой версии.')
      end

      def update_preview(params)
        return unless @selected_face && params

        @current_params = params
        params.compute_for_face(@selected_face, @orientation)
        tessellator = Core::StripeTessellator.new(@orientation)
        @preview_courses = tessellator.tessellate(@selected_face, params)
      rescue StandardError => e
        logger.error("Preview failed: #{e.message}")
        @preview_courses = []
      ensure
        Sketchup.active_model.active_view.invalidate
      end

      def create_cladding(params, entities: nil)
        return unless @selected_face

        params.compute_for_face(@selected_face, @orientation)
        params.raise_if_invalid!
        target_entities = entities || Sketchup.active_model.active_entities
        Core::Generator.new(
          face: @selected_face,
          params: params,
          orientation: @orientation,
          entities: target_entities
        ).build
      rescue StandardError => e
        logger.error("Generation failed: #{e.message}")
        UI.messagebox("Не удалось создать обшивку: #{e.message}")
      end

      def set_lod(level)
        @lod = level
      end

      def select_face(face)
        setup_orientation(face)
        @selected_face = face
        @dialog.set_context(face: face, orientation: @orientation) if @dialog
      end

      def apply_orientation(orientation)
        @orientation = orientation
        @dialog.set_context(face: @selected_face, orientation: @orientation) if @dialog && @selected_face
      end

      public :select_face

      private

      def reset_state
        @hover_face = nil
        @selected_face = nil
        @orientation = nil
        @preview_courses = []
        @current_params = nil
        @cursor_screen_point = nil
      end

      def planar?(face)
        face.normal.valid?
      end

      def update_hover_face(face)
        @hover_face = face
        return if @selected_face

        setup_orientation(face)
      end

      def clear_hover_face
        return if @selected_face

        @hover_face = nil
        @orientation = nil
        @preview_courses = []
      end

      def setup_orientation(face)
        @orientation = Core::Orientation.new(face)
      rescue StandardError => e
        logger.error("Orientation failed: #{e.message}")
        @orientation = nil
      end

      def to_world_point(u, v)
        point = Geom::Point3d.new(u, v, 0)
        @orientation.to_world(point)
      end

      def self.transparent_cursor_id
        return @transparent_cursor_id if defined?(@transparent_cursor_id)

        @transparent_cursor_id = begin
          if UI.respond_to?(:create_cursor) && File.exist?(CURSOR_IMAGE_PATH)
            UI.create_cursor(CURSOR_IMAGE_PATH, *CURSOR_HOTSPOT)
          end
        rescue StandardError => e
          Support::Logging.logger.warn("Failed to load custom cursor: #{e.message}")
          nil
        end
      end

      def store_cursor_screen_point(x, y)
        @cursor_screen_point = Geom::Point3d.new(x.to_f, y.to_f, 0.0)
      end

      def draw_preview(view)
        return unless @orientation && @preview_courses

        view.drawing_color = Sketchup::Color.new(255, 180, 40, 160)
        @preview_courses.each do |course|
          course.outer_loops.each do |loop|
            points = loop.map { |u, v| to_world_point(u, v) }
            view.draw(GL_LINE_LOOP, points)
          end
        end
      end

      def draw_cursor_overlay(view)
        return unless @cursor_screen_point

        scale = draw_scale_factor
        x = @cursor_screen_point.x / scale
        y = @cursor_screen_point.y / scale
        size = CURSOR_PIXEL_SIZE / scale

        apex = Geom::Point3d.new(x, y, 0)
        left = Geom::Point3d.new(x - size, y + size * 0.6, 0)
        right = Geom::Point3d.new(x + size * 0.3, y + size * 0.9, 0)

        view.drawing_color = Sketchup::Color.new(255, 220, 40, 255)
        view.draw2d(GL_TRIANGLES, [apex, left, right])
      end

      def draw_scale_factor
        return 1.0 unless UI.respond_to?(:scale_factor)

        major_version = Sketchup.respond_to?(:version) ? Sketchup.version.to_i : 0
        return 1.0 if major_version < 25

        factor = UI.scale_factor.to_f
        factor.positive? ? factor : 1.0
      rescue StandardError
        1.0
      end
    end
  end
end
