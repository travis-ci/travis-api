# frozen_string_literal: true

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
          c.adapter :net_http
        end
      end

      def http_options
        { ssl: Travis.config.ssl.to_h }
      end

      def request(method, name)
        resp = connection.send(method) { |req| yield(req) }
        Travis.logger.info "#{self.class.name} #{name} response status: #{resp.status}"
        if resp.success?
          resp.body.present? ? JSON.parse(resp.body)['data'] : true
        else
          raise ResponseError, "#{self.class.name} #{name} request unexpected response: #{resp.body} #{resp.status}"
        end
      end
    end
  end
end
