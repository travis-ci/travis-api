require 'travis/api/v3/service'

module Travis::API::V3
  class ProxyService < Service
    class ConfigError < StandardError; end

    # whitelist all
    def self.filter_params(params)
      params
    end

    class << self
      attr_reader :proxy_client

      def proxy(endpoint:, auth_token:)
        @proxy_client = ProxyClient.new(endpoint, auth_token)
      end
    end

    def initialize(access_control, params, env)
      raise ConfigError, "No proxy configured for #{self.class.name}" unless self.class.proxy_client
      super
    end

    def proxy!
      response = self.class.proxy_client.proxy(@env) { |r| yield r if block_given? }
      result response.body, status: response.status, result_type: :proxy
    end

    class ProxyClient
      def initialize(endpoint, auth_token)
        @connection = Faraday::Connection.new(URI(endpoint)) do |conn|
          conn.headers[:Authorization] = "Token token=\"#{auth_token}\""
          conn.response :json, content_type: 'application/json'
          conn.adapter Faraday.default_adapter
        end
      end

      def proxy(env)
        original = Rack::Request.new(env)

        request = @connection.build_request(original.request_method) do |r|
          r.params = original.params
          yield r if block_given?
        end

        # not really documented, but according to https://github.com/lostisland/faraday/blob/f08a985bd1dc380ed2d9839f1103318e2fad5f8b/lib/faraday/connection.rb#L387,
        # this is the way to execute a request previously built
        @connection.builder.build_response(@connection, request)
      end
    end
  end
end
