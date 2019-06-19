require 'json'
require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class User < Client
      def user_data(provider: :github, fullpath:, url:, code: nil, state: nil)
        resp = connection.get do |req|
          req.url 'users/user_data'
          req.params['provider'] = provider
          req.params['fullpath'] = fullpath
          req.params['url'] = url
          req.params['code'] = code
          req.params['state'] = state
        end
        return JSON.parse(resp.body)['user_data'] if resp.success?
      end
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

      def redirect_url(provider: :github, state:, fullpath:, url:)
        resp = connection.get do |req|
          req.url 'users/redirect_url'
          req.params['provider'] = provider
          req.params['state'] = state
          req.params['url'] = url
          req.params['fullpath'] = fullpath
        end
        JSON.parse(resp.body)['redirect_url'] if resp.success?
      end

      def education_data(provider:, token:)
        resp = connection.get do |req|
          req.params['provider'] = provider
          req.url 'users/education_data'
          req.params['token'] = token
        end
        JSON.parse(resp.body)['education_data'] if resp.success?
        {}
      end
    end
  end
end
