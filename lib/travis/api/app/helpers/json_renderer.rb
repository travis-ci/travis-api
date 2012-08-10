require 'travis/api/app'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module JsonRenderer
      def respond_with(resource, options = {})
        halt render_json(resource, options)
      end

      def body(value = nil, options = {}, &block)
        value = render_json(value, options) if value
        super(value, &block)
      end

      private

        def render_json(resource, options = {})
          options[:version] ||= 'v2' # TODO: Content negotiation
          options[:params]  ||= params

          builder  = Travis::Api.builder(resource, options)
          resource = builder.new(resource, options[:params]).data.to_json if builder
          resource = resource.to_json                                     if resource.is_a? Hash

          resource
        end
    end
  end
end
