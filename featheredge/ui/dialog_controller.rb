# frozen_string_literal: true

require 'json'
require_relative '../support/logging'
require_relative '../model/params'
require_relative '../support/persistence'
require_relative '../core/orientation'

module FeatherEdge
  module UI
    class DialogController
      include Support::Logging

      attr_accessor :tool

      def initialize
        @dialog = build_dialog
        @current_params = Model::Params.new
        @mode = :create
      end

      def show_for_create
        @mode = :create
        @current_params = Model::Params.new
        show_dialog
      end

      def show_for_edit(group, data)
        @mode = :edit
        @editing_group = group
        params_hash = data[:params] || {}
        @current_params = Model::Params.new(params_hash)
        face = locate_face(data[:face_persistent_id])
        if face
          orientation_data = data[:orientation]
          orientation = orientation_from_hash(face, orientation_data)
          @context_face = face
          @orientation = orientation
          tool&.select_face(face)
          tool&.apply_orientation(orientation)
          @current_params.compute_for_face(face, orientation)
        else
          logger.warn('Не удалось найти исходную грань для правки')
        end
        show_dialog
      end

      def set_context(face:, orientation:)
        @context_face = face
        @orientation = orientation
        if @current_params && face && orientation
          @current_params.compute_for_face(face, orientation)
          tool&.update_preview(@current_params.clone_with)
        end
        send_state
      end

      def update_params(params_hash)
        @current_params = Model::Params.new(params_hash)
        if @context_face && @orientation
          @current_params.compute_for_face(@context_face, @orientation)
        end
        tool&.update_preview(@current_params.clone_with)
        send_state
      rescue StandardError => e
        logger.error("Parameter update failed: #{e.message}")
        UI.messagebox("Ошибка параметров: #{e.message}")
      end

      def request_preview
        tool&.update_preview(@current_params)
      end

      def create_or_update
        return unless @context_face && @orientation

        if @mode == :edit && @editing_group&.valid?
          parent_entities = @editing_group.parent
          @editing_group.erase!
          tool.create_cladding(@current_params.clone_with, entities: parent_entities)
        else
          tool.create_cladding(@current_params.clone_with)
        end
        hide_dialog
      end

      def show_dialog
        @dialog.show
        send_state
      end

      def hide_dialog
        @dialog.close
      end

      private

      def build_dialog
        dialog = UI::HtmlDialog.new(
          dialog_title: 'FeatherEdge',
          width: 420,
          height: 620,
          resizable: true,
          style: UI::HtmlDialog::STYLE_DIALOG
        )
        dialog.set_file(File.join(__dir__, 'dialog.html'))
        register_callbacks(dialog)
        dialog
      end

      def register_callbacks(dialog)
        dialog.add_action_callback('ready') do |_context|
          send_state
        end

        dialog.add_action_callback('apply') do |_context, json|
          params_hash = JSON.parse(json, symbolize_names: true)
          update_params(params_hash)
        end

        dialog.add_action_callback('create') do |_context|
          create_or_update
        end

        dialog.add_action_callback('request_preview') do |_context|
          request_preview
        end
      end

      def send_state
        @current_params.valid?
        state = {
          mode: @mode,
          params: @current_params.to_h,
          warnings: @current_params.warnings
        }
        js = "window.sketchup && sketchup.updateState(#{JSON.generate(state)})"
        @dialog.execute_script(js)
      end

      def locate_face(pid)
        return unless pid

        Support::Persistence.find_entity_by_pid(Sketchup.active_model, pid)
      end

      def orientation_from_hash(face, data)
        return Core::Orientation.new(face) unless data

        orientation = Core::Orientation.new(face)
        u = Geom::Vector3d.new(data[:u_axis]) if data[:u_axis]
        v = Geom::Vector3d.new(data[:v_axis]) if data[:v_axis]
        if u && v
          orientation.instance_eval do
            @u_axis = u
            @v_axis = v
            build_transforms
          end
        end
        orientation
      end
    end
  end
end
