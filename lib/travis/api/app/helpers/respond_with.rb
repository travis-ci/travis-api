require 'travis/api/app'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module RespondWith
      def respond_with(resource, options = {})
        options[:format] ||= env['travis.format']
        result = respond(resource, options)
        result = result ? result.to_json : 404
        halt result
      end

      def body(value = nil, options = {}, &block)
        value = value.to_json if value.is_a?(Hash)
        super(value, &block)
      end

      private

        def respond(resource, options)
          responders(resource, options).each do |const|
            responder = const.new(self, resource, options)
            resource = responder.apply if responder.apply?
          end
          resource
        end

        def responders(resource, options)
          [:Service, :Json, :Image, :Xml].map do |name|
            Responders.const_get(name)
          end
        end
    end
  end
end
