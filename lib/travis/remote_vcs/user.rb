require 'json'
require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class User < Client
      def handshake(provider: :github, fullpath:, url:, code:, state:, payload:)
        resp = connection.get do |req|
          req.url 'users/handshake'
          req.params['provider'] = provider
          req.params['fullpath'] = fullpath
          req.params['url'] = url
          req.params['code'] = code
          req.params['state'] = state
          req.params['payload'] = payload
        end
        return JSON.parse(resp.body)['data'] if resp.success?
      end

      def generate_token(provider: :github, token:, app_id: 1)
        resp = connection.get do |req|
          req.url 'users/generate_token'
          req.params['provider'] = provider
          req.params['token'] = token
          req.params['app_id'] = app_id
        end
        return JSON.parse(resp.body)['data'] if resp.success?
      end
    end
  end
end
