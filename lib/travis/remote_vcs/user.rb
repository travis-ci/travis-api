require 'json'
require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class User < Client
      def auth_request(provider: :github, redirect_uri:, state:)
        resp = connection.get do |req|
          req.url 'users/session/new'
          req.params['provider'] = provider
          req.params['redirect_uri'] = redirect_uri
          req.params['state'] = state
        end
        Travis.logger.info "REMOTE VCS USER auth_request #{resp.success?}"
        return JSON.parse(resp.body)['data'] if resp.success?

        raise ConnectionError
      end

      def authenticate(provider: :github, code:, redirect_uri:)
        resp = connection.post do |req|
          req.url 'users/session'
          req.params['provider'] = provider
          req.params['code'] = code
          req.params['redirect_uri'] = redirect_uri
        end
        Travis.logger.info "REMOTE VCS USER authenticate #{resp.success?}"
        return JSON.parse(resp.body)['data'] if resp.success?

        raise ConnectionError
      end

      def generate_token(provider: :github, token:, app_id: 1)
        resp = connection.post do |req|
          req.url 'users/session/generate_token'
          req.params['provider'] = provider
          req.params['token'] = token
          req.params['app_id'] = app_id
        end
        Travis.logger.info "REMOTE VCS USER generate_token #{resp.success?}"
        return JSON.parse(resp.body)['data'] if resp.success?

        raise ConnectionError
      end

      def sync(user_id:)
        resp = connection.post { |req| req.url "users/#{user_id}/sync_data" }
        raise raise ConnectionError unless resp.success?

        true
      end

      def check_scopes(user_id:)
        resp = connection.post { |req| req.url "users/#{user_id}/check_scopes" }
        raise raise ConnectionError unless resp.success?

        true
      end
    end
  end
end
