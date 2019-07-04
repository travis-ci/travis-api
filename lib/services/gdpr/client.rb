module Services
  module Gdpr
    class Client
      include ApplicationHelper
      class Error < StandardError; end

      attr_reader :sender

      def initialize(sender)
        @sender = sender
      end

      def export
        handle_response connection.post("/user/#{sender.id}/export")
      end

      def purge
        handle_response connection.delete("/user/#{sender.id}")
      end

      private

      def handle_response(response)
        raise Error, "Unexpected response #{response.status}" unless response.status == 204
      end

      def connection
        @_connection ||= Faraday.new(url: travis_config.gdpr.endpoint) do |c|
          c.headers['X-Travis-Source'] = 'admin'
          c.headers['X-Travis-Sender'] = sender.login
          c.token_auth travis_config.gdpr.auth_token
          c.adapter Faraday.default_adapter
        end
      end

      def travis_config
        TravisConfig.load
      end
    end
  end
end