# frozen_string_literal: true

require 'json'
require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class User < Client
      def auth_request(provider: :github, redirect_uri:, state:, signup:)
        request(:get, __method__) do |req|
          req.url 'users/session/new'
          req.params['provider'] = provider
          req.params['redirect_uri'] = redirect_uri
          req.params['state'] = state
          req.params['signup'] = signup
        end
      end

      def authenticate(provider: :github, code:, redirect_uri:, cluster: nil)
        request(:post, __method__) do |req|
          req.url 'users/session'
          req.params['provider'] = provider
          req.params['code'] = code
          req.params['redirect_uri'] = redirect_uri
          req.params['cluster'] = cluster unless cluster.nil?
        end
      end

      def generate_token(provider: :github, token:, app_id: 1)
        request(:post, __method__) do |req|
          req.url 'users/session/generate_token'
          req.params['provider'] = provider
          req.params['token'] = token
          req.params['app_id'] = app_id
        end
      end

      def sync(user_id:)
        request(:post, __method__) do |req|
          req.url "users/#{user_id}/sync_data"
        end && true
      end

      def check_scopes(user_id:)
        request(:post, __method__) do |req|
          req.url "users/#{user_id}/check_scopes"
        end && true
      end

      def confirm_user(token:)
        request(:post, __method__) do |req|
          req.url 'users/confirm'
          req.params['token'] = token
        end
      end

      def request_confirmation(id:)
        request(:post, __method__) do |req|
          req.url 'users/request_confirmation'
          req.params['id'] = id
        end
      end
    end
  end
end
