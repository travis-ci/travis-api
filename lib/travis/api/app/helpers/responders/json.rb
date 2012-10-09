module Travis::Api::App::Helpers::Responders
  class Json < Base
    ACCEPT_VERSION  = /vnd\.travis-ci\.(\d+)\+/
    DEFAULT_VERSION = 'v2'

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
        request.accept.join =~ ACCEPT_VERSION && "v#{$1}" || DEFAULT_VERSION
      end
  end
end
