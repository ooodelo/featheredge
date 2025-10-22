# frozen_string_literal: true

require_relative '../app'
require_relative '../support/logging'
require_relative '../core/attribute_store'

module FeatherEdge
  module Commands
    class EditCladdingCommand < BaseCommand
      include Support::Logging

      def initialize
        super('Правка обшивки…', id: 'featheredge_edit') do
          activate
        end
        self.tooltip = 'Редактировать ранее созданную обшивку FeatherEdge'
        self.status_bar_text = 'Выберите группу обшивки, чтобы отредактировать её параметры.'
      end

      def context_menu?
        selected_group?
      end

      def activate
        group = selected_group
        unless group
          ::UI.messagebox('Выберите группу обшивки FeatherEdge для правки.')
          return
        end

        data = App.attribute_store.load(group)
        unless data
          ::UI.messagebox('В выбранной группе нет данных FeatherEdge.')
          return
        end

        App.dialog.show_for_edit(group, data)
      end

      private

      def selected_group
        selection = Sketchup.active_model.selection
        selection.grep(Sketchup::Group).find do |group|
          App.attribute_store.featheredge_group?(group)
        end
      end

      def selected_group?
        !selected_group.nil?
      end
    end
  end
end
