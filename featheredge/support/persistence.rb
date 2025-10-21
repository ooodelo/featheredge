# frozen_string_literal: true

module FeatherEdge
  module Support
    module Persistence
      module_function

      def find_entity_by_pid(model, pid)
        stack = [model]
        until stack.empty?
          container = stack.pop
          entities = if container.respond_to?(:entities)
                       container.entities
                     elsif container.respond_to?(:definition)
                       container.definition.entities
                     else
                       next
                     end
          entities.each do |entity|
            return entity if entity.persistent_id == pid
            stack << entity if entity.respond_to?(:entities)
          end
        end
        nil
      end
    end
  end
end
