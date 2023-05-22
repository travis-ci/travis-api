# frozen_string_literal: true

module Travis::API::V3

  class AuthorizerError < StandardError; end
  class AuthorizerConfigError < AuthorizerError; end
  class AuthorizerConnectionError < AuthorizerError; end
  class Authorizer


    def initialize(user_id)
      @user_id = user_id
    end

    def for_repo(repo_id, perm)
      response = connection.get("/repo/#{repo_id}/#{perm}")
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def for_account(org_id, perm)
      response = connection.get("/org/#{org_id}/#{perm}")
      handle_response(response)

    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    alias :for_org :for_account

    def has_repo_role?(repo_id, role)
      response = connection.get("roles/repo/:id")
      if handle_response(response) && response.status == 200
        response.body.include?('roles') && response.body['roles']&.include?(role)
      end

    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def has_org_role?(org_id, role)
      response = connection.get("roles/org/:id")
      if handle_response(response) && response.status == 200
        response.body.include?('roles') && response.body['roles']&.include?(role)
      end

    rescue Faraday::Error
      raise AuthorizerConnectionError
    end


    private

    def handle_response(response)
      case response.status
      when 200, 201, 202, 204
        true
      when 400,403,404
        false
      else
        raise Travis::API::V3::AuthorizerError, 'Authorizer failed'
      end
    end

    def connection(timeout: 3)
      @connection ||= Faraday.new(url: authorizer_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.basic_auth '_', authorizer_auth_key
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['Content-Type'] = 'application/json'
        conn.request :json
        conn.response :json
        conn.options[:open_timeout] = timeout
        conn.options[:timeout] = timeout
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter :net_http
      end
    end

    def authorizer_url
      Travis.config.authorizer.url || raise(AuthorizerConfigError, 'No authorizer url configured')
    end

    def authorizer_auth_key
      Travis.config.authorizer.auth_key || raise(AuthorizerConfigError, 'No authorizer auth key configured')
    end
  end
end
