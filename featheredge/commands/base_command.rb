# frozen_string_literal: true

module FeatherEdge
  module Commands
    class BaseCommand < UI::Command
      attr_reader :id

      def initialize(name, id: nil, &block)
        super(name, &block)
        @id = id || name.downcase.gsub(/\s+/, '_')
      end

      def context_menu?
        false
      end
    end
  end
end
