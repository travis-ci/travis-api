require 'active_model_serializers'

# This hideousness courtesy of http://stackoverflow.com/a/8339255
module ActiveSupport::JSON::Encoding
  def self.escape(string)
    string = string.encode(::Encoding::UTF_8, :undef => :replace).force_encoding(::Encoding::BINARY)
    json = string.gsub(escape_regex) { |s| ESCAPED_CHARS[s] }
    json = %("#{json}")
    json.force_encoding(::Encoding::UTF_8)
  end
end

module Travis
  module Api
    module Serialize
      class ObjectSerializer < ActiveModel::Serializer
        def data
          if self.root
            { "#{self.root}" => as_json }.as_json
          else
            as_json
          end
        end
      end

      class ArraySerializer < ActiveModel::Serializer::CollectionSerializer
        def data
          if self.root
            { "#{self.root}" => as_json }.as_json
          else
            as_json
          end
        end

        def initialize(resource, options)
          options[:each_serializer] ||= V2::Http.const_get(options[:root].to_s.singularize.camelize)
          options[:serializer] = options[:each_serializer]
          super(resource, options)
        end
      end
    end
  end
end
