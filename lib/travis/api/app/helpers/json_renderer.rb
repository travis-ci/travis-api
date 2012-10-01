require 'travis/api/app'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module JsonRenderer
      ACCEPT_VERSION  = /vnd\.travis-ci\.(\d+)\+/
      DEFAULT_VERSION = 'v1'

      def respond_with(resource, options = {})
        halt render_json(resource, options)
      end

      def body(value = nil, options = {}, &block)
        value = render_json(value, options) if value
        super(value, &block)
      end

      private

        def render_json(resource, options = {})
          options[:version] ||= api_version
          options[:params]  ||= params

          builder  = Travis::Api.builder(resource, options)
          # builder || raise("could not determine a builder for #{resource}, #{options}")
          resource = builder.new(resource, options[:params]).data.to_json if builder
          resource = resource.to_json                                     if resource.is_a? Hash
          resource
        end

        def api_version
          accept = request.env['HTTP_ACCEPT'] || ''
          accept =~ ACCEPT_VERSION && "v#{$1}" || DEFAULT_VERSION
        end
    end
  end
end
