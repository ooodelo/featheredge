# frozen_string_literal: true

require_relative '../app'

module FeatherEdge
  module Commands
    class TogglePreviewLodCommand < BaseCommand
      def initialize
        super('Toggle FeatherEdge Preview LOD', id: 'featheredge_toggle_lod') do
          activate
        end
        self.tooltip = 'Переключить режим детализации предпросмотра'
        self.status_bar_text = 'Переключает LOD предпросмотра инструмента.'
        self.set_validation_proc { MF_ENABLED }
      end

      def activate
        App.face_pick_tool.toggle_lod!
      end

      def context_menu?
        false
      end
    end
  end
end
