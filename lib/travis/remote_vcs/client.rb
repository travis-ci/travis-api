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
          c.adapter :net_http
        end
      end

      def http_options
        { ssl: Travis.config.ssl.to_h }
      end

      def request(method, name, data_in_body = true)
        resp = connection.send(method) { |req| yield(req) }

        raise ResponseError, "#{self.class.name} #{name} request unexpected response: #{resp.body} #{resp.status}" unless resp.success?
        return true unless resp.body.present?

        parsed_response = JSON.parse(resp.body)
        data_in_body ? parsed_response['data'] : parsed_response
      end
    end
  end
end
