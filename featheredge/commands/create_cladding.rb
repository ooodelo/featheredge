# frozen_string_literal: true

require_relative '../app'
require_relative '../support/logging'

module FeatherEdge
  module Commands
    class CreateCladdingCommand < BaseCommand
      include Support::Logging

      def initialize
        super('Создать обшивку (featheredge)…', id: 'featheredge_create') do
          activate
        end
        self.tooltip = 'Создать FeatherEdge обшивку на выбранной грани'
        self.status_bar_text = 'Выберите плоскую грань и настройте параметры обшивки.'
        self.set_validation_proc { MF_ENABLED }
      end

      def activate
        logger.info('Activating face pick tool for creation')
        tool = App.face_pick_tool
        tool.mode = :create
        Sketchup.active_model.tools.push_tool(tool)
        App.dialog.show_for_create
      end
    end
  end
end
