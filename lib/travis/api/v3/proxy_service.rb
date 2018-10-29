require 'travis/api/v3/service'
require 'rack/proxy'

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
      status, _headers, body = self.class.proxy_client.call(@env)
      response_body = body.join("\n")
      data = begin
        JSON.parse(response_body)
      rescue JSON::ParserError
        response_body
      end

      result data, status: status, result_type: :proxy
    end

    class ProxyClient < Rack::Proxy
      def initialize(endpoint, auth_token)
        @endpoint = URI(endpoint)
        @auth_token = auth_token
        super(streaming: false)
      end

      def rewrite_env(env)
        env['HTTPS'] = @endpoint.scheme == 'https' ? 'on' : 'off'
        env['SERVER_PORT'] = @endpoint.port.to_s
        env['HTTP_HOST'] = @endpoint.host
        env['SCRIPT_NAME'] = @endpoint.path
        env['PATH_INFO'] = nil
        env['HTTP_AUTHORIZATION'] = "Token token=\"#{@auth_token}\""
        env
      end
    end
  end
end
