class Travis::Api::App
  module Responders
    class Json < Base
      include Helpers::Accept

      def apply?
        super && !resource.is_a?(String) && !resource.nil?
      end

      def apply
        halt result.to_json
      end

      private

        def result
          builder ? builder.new(resource, request.params).data : resource
        end

        def builder
          @builder ||= Travis::Api.builder(resource, { :version => accept_version }.merge(options))
        end
    end
  end
end
