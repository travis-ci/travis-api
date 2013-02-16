require 'travis/api/app'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module RespondWith
      include Accept

      def respond_with(resource, options = {})
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
          resource = apply_service_responder(resource, options)

          response = acceptable_formats.find do |accept|
            responders(resource, options).find do |const|
              responder = const.new(self, resource, options.dup.merge(accept: accept))
              responder.apply if responder.apply?
            end
          end

          response || (resource ? error(406) : error(404))
        end

        def apply_service_responder(resource, options)
          responder = Responders::Service.new(self, resource, options)
          resource  = responder.apply if responder.apply?
          resource
        end

        def responders(resource, options)
          [:Json, :Image, :Xml, :Plain].map do |name|
            Responders.const_get(name)
          end
        end
    end
  end
end
