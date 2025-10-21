# frozen_string_literal: true

require_relative 'commands/base_command'
require_relative 'commands/create_cladding'
require_relative 'commands/edit_cladding'
require_relative 'commands/flip_direction'
require_relative 'commands/toggle_preview_lod'

module FeatherEdge
  module Commands
    extend Support::Logging

    def self.register!
      menu = UI.menu('Extensions').add_submenu('FeatherEdge')
      register_command(menu, CreateCladdingCommand)
      register_command(menu, EditCladdingCommand)
      register_command(menu, FlipDirectionCommand)
      register_command(menu, TogglePreviewLodCommand)
    end

    def self.register_command(menu, klass)
      command = klass.new
      menu.add_item(command)
      UI.add_context_menu_handler do |context_menu|
        next unless command.respond_to?(:context_menu?) && command.context_menu?

        context_menu.add_item(command)
      end
      logger.info("Registered command #{klass}")
    end
  end
end
