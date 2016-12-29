require 'active_model_serializers'

# This hideousness courtesy of http://stackoverflow.com/a/8339255
module ActiveSupport::JSON::Encoding
  class << self
    def escape(string)
      if string.respond_to?(:force_encoding)
        string = string.encode(::Encoding::UTF_8, :undef => :replace).force_encoding(::Encoding::BINARY)
      end
      json = string.gsub(escape_regex) { |s| ESCAPED_CHARS[s] }
      json = %("#{json}")
      json.force_encoding(::Encoding::UTF_8) if json.respond_to?(:force_encoding)
      json
    end
  end
end

module Travis
  module Api
    module Serialize
      class ObjectSerializer < ActiveModel::Serializer
        def data
          as_json
        end
      end

      class ArraySerializer < ActiveModel::ArraySerializer
        def data
          as_json
        end

        def initialize(resource, options)
          options[:each_serializer] ||= V2::Http.const_get(options[:root].to_s.singularize.camelize)
          super(resource, options)
        end
      end
    end
  end
end
