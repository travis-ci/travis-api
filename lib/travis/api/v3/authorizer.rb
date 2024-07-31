# frozen_string_literal: true

module Travis::API::V3

  class AuthorizerError < StandardError; end
  class AuthorizerConfigError < AuthorizerError; end
  class AuthorizerConnectionError < AuthorizerError; end
  class Authorizer


    def initialize(user_id)
      @user_id = user_id
    end

    def cache_repos(repo_ids)
      cache.cache_repos(repo_ids, 'permissions')
      cache.cache_repos(repo_ids, 'roles')
    end

    def for_repo(repo_id, perm)
      cache.get_permission('repository', repo_id, perm)
    end

    def for_account(org_id, perm)
      cache.get_permission('organization', org_id, perm)
    end

    def has_repo_role?(repo_id, role)
      cache.get_role('repository', repo_id, role)
    end

    def has_org_role?(org_id, role)
      cache.get_role('organization', org_id, role)
    end

    def patch_all_org_repos(org_id, roles)
      response = connection.patch("/org/#{org_id}/repos") do |req|
        req.body={roles: roles}
      end
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def delete_all_org_repos(org_id, roles)
      response = connection.delete("/org/#{org_id}/repos") do |req|
        req.body = {roles: roles}
      end
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def delete_repo_build_permission(repo_id)
      response = connection.delete("/repo_build_permission/#{repo_id}")
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def add_repo_build_permission(repo_id)
      response = connection.post("/repo_build_permission/#{repo_id}")
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def patch_repo_roles(repo_id, roles)
      response = connection.patch("/repo/#{repo_id}") do |req|
        req.body={roles: roles}
      end
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def delete_repo_roles(repo_id, roles)
      response = connection.delete("/repo/#{repo_id}") do |req|
        req.body = {roles: roles}
      end
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def for_repox(repo_id, perm)
      response = connection.get("/repo/#{repo_id}/#{perm}")
      handle_response(response)
    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def for_accountx(org_id, perm)
      response = connection.get("/org/#{org_id}/#{perm}")
      handle_response(response)

    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    alias :for_org :for_account

    def has_repo_rolex?(repo_id, role)
      response = connection.get("roles/repo/#{repo_id}")
      if handle_response(response) && response.status == 200
        response.body.include?('roles') && response.body['roles']&.include?(role)
      end

    rescue Faraday::Error
      raise AuthorizerConnectionError
    end

    def has_org_rolex?(org_id, role)
      response = connection.get("roles/org/#{org_id}")
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

    def cache
      @_cache ||= Cache.new(@user_id)
    end

    def connection
      @_connection ||= AuthorizerClient.new(@user_id).connection
    end

    class Cache
      def initialize(user_id)
        @user_id = user_id
      end



      def cache_repos(repo_ids, type = 'permissions')
        ids = repo_ids.select do |id|
          redis.smembers("api::role_cache::#{@user_id}::repository::#{id}::#{type}")&.empty?
        end

        response = connection.post("/#{type}/repositories") do |req|
          req.body = {repository_ids: ids}.to_json
        end unless ids.empty?

        if response&.status == 200
          body = response.body.is_a?(String) && response.body.length > 0 ? JSON.parse(response.body) : response.body
          body["#{type}"]&.keys&.each do |id|
            key = "api::role_cache::#{@user_id}::repository::#{id}::#{type}"
            perms = body["#{type}"][id]
            redis.sadd(key, (perms.nil? || perms.empty?) ? ['none'] : perms)
            redis.expire(key,15)
          end
        end
      end

      def get_permission(resource_type, resource_id, permission)
        key = "api::role_cache::#{@user_id}::#{resource_type.downcase}::#{resource_id}::permissions"
        if redis.exists?(key)
          data = redis.smembers(key)
          data.include?(permission)
        else
          response = connection.get("/permissions/#{resource_type == 'repository' ? 'repo' : 'org'}/#{resource_id}")
          unless response.status == 200 && response.body&.include?('permissions')
            Travis.logger.warn("Authorizer permission response error: #{response.status} for user: #{@user_id}, resource: #{resource_type}: #{resource_id}")
            raise Travis::API::V3::AuthorizerError
          end

          body = response.body.is_a?(String) && response.body.length > 0 ? JSON.parse(response.body) : response.body

          redis.sadd(key, body['permissions'].nil? || body['permissions'].empty? ? ['none'] : body['permissions'])
          redis.expire(key, 15)

          body['permissions']&.include?(permission)
        end
      rescue Faraday::Error
        raise Travis::API::V3::AuthorizerConnectionError
      end

      def get_role(resource_type, resource_id, role)
        key = "api::role_cache::#{@user_id}::#{resource_type.downcase}::#{resource_id}::roles"
        if redis.exists?(key)
          data = redis.smembers(key)
          data.include?(role)
        else
          response = connection.get("/roles/#{resource_type == 'repository' ? 'repo' : 'org'}/#{resource_id}")
          unless response.status == 200 && response.body&.include?('roles')
            Travis.logger.warn("Authorizer role response error: #{response.status} for user: #{@user_id}, resource: #{resource_type}: #{resource_id}")
            raise Travis::API::V3::AuthorizerError
          end

          body = response.body.is_a?(String) && response.body.length > 0 ? JSON.parse(response.body) : response.body

          redis.sadd(key, body['roles'].nil? || body['roles'].empty? ? ['none'] : body['roles'])
          redis.expire(key, 5)

          body['roles']&.include?(role)
        end
      rescue Faraday::Error
        raise Travis::API::V3::AuthorizerConnectionError
      end

      def redis
        @_redis ||= Travis.redis
      end

      def connection
        @_connection ||= AuthorizerClient.new(@user_id).connection
      end
    end

    class AuthorizerClient
      def initialize(user_id)
        @user_id = user_id
      end

      def connection(timeout: 3)
        @connection ||= Faraday.new(url: authorizer_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
          conn.request :authorization, :basic, '_', authorizer_auth_key
          conn.headers['X-Travis-User-Id'] = @user_id.to_s
          conn.headers['X-Travis-Origin'] = 'api'
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
        Travis.config.authorizer.url || raise(Travis::API::V3::AuthorizerConfigError, 'No authorizer url configured')
      end

      def authorizer_auth_key
        Travis.config.authorizer.auth_key || raise(Travis::API::V3::AuthorizerConfigError, 'No authorizer auth key configured')
      end
    end
  end
end
