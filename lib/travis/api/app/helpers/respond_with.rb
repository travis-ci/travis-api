require 'travis/api/app'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module RespondWith
      def respond_with(resource, options = {})
        options[:format] ||= format_from_content_type || params[:format] || 'json'
        halt respond(resource, options).to_json
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

        # TODO is there no support for this kind of mime types?
        def format_from_content_type
          request.content_type && request.content_type.split(';').first.split('/').last
        end
    end
  end
end
