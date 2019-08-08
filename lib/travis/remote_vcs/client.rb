require 'faraday'
require 'singleton'

module Travis
  class RemoteVCS
    class Client
      private

      def connection
        @connection ||= Faraday.new(http_options.merge(url: Travis.config.vcs.url)) do |c|
          c.request :authorization, :token, Travis.config.vcs.token
          c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
          c.use :instrumentation
          c.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
          c.adapter :net_http_persistent
        end
      end

      def http_options
        { ssl: Travis.config.ssl.to_h }
      end
    end
  end
end
