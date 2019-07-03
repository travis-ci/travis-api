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
        @_connection ||= Faraday.new(url: 'https://gdpr.travis-ci.com') do |c|
          c.headers['X-Travis-Source'] = 'admin'
          c.headers['X-Travis-Sender'] = sender.login
          c.token_auth 'token'
          c.adapter Faraday.default_adapter
        end
      end
    end
  end
end