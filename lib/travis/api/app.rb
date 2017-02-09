require 'rack/contrib/post_body_content_type_parser'
require 'rack/ssl'
require 'rack-timeout'
require 'raven'
require 'raven/integrations/rack'

module Travis
  module API
    module App
      extend self

      def router
        @router ||= Travis::API::V3::Router.new
      end

      def new(options = {})
        app = self

        Rack::Builder.app do
          if Travis.production?
            use Raven::Rack
            use Rack::SSL
          end

          use Travis::API::CORS
          use Rack::Timeout
          use Rack::Deflater
          use Rack::PostBodyContentTypeParser
          use Travis::API::ResponseCleaner

          map('/v3') { run app.router }
          run app.router
        end
      end
    end
  end
end
