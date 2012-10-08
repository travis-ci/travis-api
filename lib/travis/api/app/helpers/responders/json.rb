module Travis::Api::App::Helpers::Responders
  class Json < Base
    ACCEPT_VERSION  = /vnd\.travis-ci\.(\d+)\+/
    DEFAULT_VERSION = 'v2'

    def render
      options[:version] ||= version
      builder  = Travis::Api.builder(resource, options) || raise_undefined_builder
      resource = builder.new(self.resource, request.params).data
      resource = resource.to_json unless resource.is_a?(String)
      resource
    end

    private

      def version
        request.accept.join =~ ACCEPT_VERSION && "v#{$1}" || DEFAULT_VERSION
      end

      def raise_undefined_builder
        raise("could not determine a builder for #{resource}, #{options}")
      end
  end
end
