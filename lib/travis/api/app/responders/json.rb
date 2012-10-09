module Travis::Api::App::Responders
  class Json < Base
    def apply?
      options[:format] == 'json' && !resource.is_a?(String)
    end

    def apply
      halt result.to_json
    end

    private

      def result
        builder ? builder.new(resource, request.params).data : resource
      end

      def builder
        @builder ||= Travis::Api.builder(resource, { :version => version }.merge(options))
      end

      def version
        API.version(request.accept.join)
      end
  end
end
