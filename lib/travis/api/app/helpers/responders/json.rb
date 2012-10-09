module Travis::Api::App::Helpers::Responders
  class Json < Base
    ACCEPT_VERSION  = /vnd\.travis-ci\.(\d+)\+/
    DEFAULT_VERSION = 'v2'

    def apply?
      !resource.is_a?(String) && options[:format] == 'json'
    end

    def apply
      resource = builder.new(self.resource, request.params).data if builder
      resource ||= self.resource || {}
      resource.merge!(flash: flash) unless flash.empty?
      halt resource.to_json
    end

    private

      def builder
        @builder ||= Travis::Api.builder(resource, { :version => version }.merge(options))
      end

      def version
        request.accept.join =~ ACCEPT_VERSION && "v#{$1}" || DEFAULT_VERSION
      end
  end
end
