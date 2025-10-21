# frozen_string_literal: true

require 'json'
require 'time'

module FeatherEdge
  module Core
    class AttributeStore
      DICTIONARY = 'featheredge'
      KEY = 'config'

      def save(group, params, face, orientation)
        data = {
          version: FeatherEdge::VERSION,
          params: params.to_h,
          face_persistent_id: face.persistent_id,
          orientation: orientation.to_h,
          group_transform: group.transformation.to_a,
          timestamp: Time.now.utc.iso8601
        }
        dict = group.attribute_dictionary(DICTIONARY, true)
        dict[KEY] = JSON.generate(data)
        data
      end

      def load(group)
        dict = group.attribute_dictionary(DICTIONARY)
        return unless dict&.[]?(KEY)

        JSON.parse(dict[KEY], symbolize_names: true)
      rescue JSON::ParserError
        nil
      end

      def featheredge_group?(group)
        dict = group.attribute_dictionary(DICTIONARY)
        dict&.[]?(KEY)
      end
    end
  end
end
