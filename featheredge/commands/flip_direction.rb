# frozen_string_literal: true

require_relative '../app'

module FeatherEdge
  module Commands
    class FlipDirectionCommand < BaseCommand
      def initialize
        super('Flip FeatherEdge Direction', id: 'featheredge_flip_direction') do
          activate
        end
        self.tooltip = 'Поменять направление рядов обшивки в инструменте выбора'
        self.status_bar_text = 'Переключает направление рядов (U/V) в режиме предпросмотра.'
        self.set_validation_proc { MF_ENABLED }
      end

      def activate
        tool = App.face_pick_tool
        tool.flip_direction!
      end

      def context_menu?
        false
      end
    end
  end
end
