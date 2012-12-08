class Travis::Api::App
  module Responders
    class Json < Base
      include Helpers::Accept

      def apply?
        options[:format] == 'json' && !resource.is_a?(String) && !resource.nil?
      end

      def apply
        halt (result ? result.to_json : 404)
      end

      private

        def result
          builder ? builder.new(resource, request.params).data : basic_type_resource
        end

        def builder
          @builder ||= Travis::Api.builder(resource, { :version => accept_version }.merge(options))
        end

        def basic_type_resource
          resource if resource.is_a?(Hash)
        end
    end
  end
end
