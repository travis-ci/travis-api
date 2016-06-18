require 'active_model_serializers'

module Travis
  module Api
    class Serializer < ActiveModel::Serializer
      def data
        as_json
      end
    end

    class ArraySerializer < ActiveModel::ArraySerializer
      def data
        as_json
      end

      def initialize(resource, options)
        options[:each_serializer] ||= Travis::Api::Serialize::V2::Http.const_get(options[:root].to_s.singularize.camelize)
        super(resource, options)
      end
    end
  end
end

