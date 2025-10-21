# frozen_string_literal: true

require_relative 'ui/dialog_controller'
require_relative 'tool/face_pick_tool'
require_relative 'core/attribute_store'

module FeatherEdge
  module App
    extend Support::Logging

    class << self
      def dialog
        @dialog ||= UI::DialogController.new
      end

      def face_pick_tool
        @face_pick_tool ||= Tool::FacePickTool.new(dialog: dialog)
      end

      def reset_tool!
        @face_pick_tool = nil
      end

      def attribute_store
        @attribute_store ||= Core::AttributeStore.new
      end
    end
  end
end
