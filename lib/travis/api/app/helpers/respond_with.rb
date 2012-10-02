require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Responders
      autoload :Base,  'travis/api/app/helpers/responders/base'
      autoload :Image, 'travis/api/app/helpers/responders/image'
      autoload :Json,  'travis/api/app/helpers/responders/json'
      autoload :Xml,   'travis/api/app/helpers/responders/xml'
    end

    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module RespondWith
      def respond_with(resource, options = {})
        halt responder.new(request, headers, resource, options).render
      end

      def body(value = nil, options = {}, &block)
        value = value.to_json if value.is_a?(Hash)
        super(value, &block)
      end

      private

        def responder
          Responders.const_get(responder_type.to_s.camelize) # or raise shit
        end

        def responder_type
          format_from_content_type || params[:format] || 'json'
        end

        # TODO is there no support for this kind of mime types?
        def format_from_content_type
          request.content_type && request.content_type.split(';').first.split('/').last
        end
    end
  end
end
