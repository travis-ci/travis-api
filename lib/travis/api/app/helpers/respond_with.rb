require 'travis/api/app'
require 'travis/api/app/helpers/accept'
require 'travis/api/app/responders'

class Travis::Api::App
  module Helpers
    # Allows routes to return either hashes or anything Travis::API.data can
    # convert (in addition to the return values supported by Sinatra, of
    # course). These values will be encoded in JSON.
    module RespondWith
      include Accept

      STATUS = {
        success: 200,
        not_found: 404
      }

      def respond_with(resource, options = {})
        result = respond(resource, options)

        if result && response.content_type =~ /application\/json/
          status STATUS[result[:result]] if result.is_a?(Hash) && result[:result].is_a?(Symbol)
          result = prettify_result? ? JSON.pretty_generate(result) : result.to_json
        end

        halt result || 404
      end

      def body(value = nil, options = {}, &block)
        value = value.to_json if value.is_a?(Hash)
        super(value, &block)
      end

      private

        def respond(resource, options)
          resource = apply_service_responder(resource, options)
          response = nil
          responders = responders_for(options)

          acceptable_formats.find do |accept|
            responders.find do |const|
              responder = const.new(self, resource, options.dup.merge(accept: accept))
              response = responder.apply if responder.apply?
            end
          end

          response || (resource ? error(406) : error(404))
        end

        def prettify_result?
          !params[:pretty].nil? && (params[:pretty].downcase == 'true' || params[:pretty].to_i > 0)
        end

        def apply_service_responder(resource, options)
          responder = Responders::Service.new(self, resource, options)
          resource  = responder.apply if responder.apply?
          resource
        end

        def format_responders(formats)
          Array(formats).map do |name|
            Responders.const_get(name.to_s.camelize)
          end
        end

        # TODO can we remove Plain?
        RESPONDERS = [:Json, :Plain]

        def responders_for(opts)
          names = Array(opts[:responders] || opts[:responder] || RESPONDERS)
          names.map { |name| Responders.const_get(name.to_s.camelize) }
        end
    end
  end
end
