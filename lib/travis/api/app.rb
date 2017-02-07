require 'rack/contrib/post_body_content_type_parser'
require 'rack/ssl'
require 'rack-timeout'

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
          use Travis::API::CORS
          use Rack::Timeout
          use Rack::Deflater
          use Rack::PostBodyContentTypeParser
          use Rack::SSL if Travis.production?
          use Travis::API::ResponseCleaner

          map('/v3') { run app.router }
          run app.router
        end
      end
    end
  end
end
