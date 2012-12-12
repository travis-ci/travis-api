require 'travis/api/app'
require 'securerandom'

class Travis::Api::App
  class AccessToken
    DEFAULT_SCOPES = [:public, :private]
    attr_reader :token, :scopes, :user_id, :app_id

    def self.create(options = {})
      new(options).tap(&:save)
    end

    def self.for_travis_token(travis_token, options = {})
      travis_token = Token.find_by_token(travis_token) unless travis_token.respond_to? :user
      new(scope: :travis_token, app_id: 1, user: travis_token.user).tap(&:save) if travis_token
    end

    def self.find_by_token(token)
      return token if token.is_a? self
      user_id, app_id, *scopes = redis.lrange(key(token), 0, -1)
      new(token: token, scopes: scopes, user_id: user_id, app_id: app_id) if user_id
    end

    def initialize(options = {})
      raise ArgumentError, 'must supply either user_id or user' unless options.key?(:user) ^ options.key?(:user_id)
      raise ArgumentError, 'must supply app_id' unless options.key?(:app_id)

      @app_id   = Integer(options[:app_id])
      @scopes   = Array(options[:scopes] || options[:scope] || DEFAULT_SCOPES).map(&:to_sym)
      @user     = options[:user]
      @user_id  = Integer(options[:user_id] || @user.id)
      @token    = options[:token] || reuse_token || SecureRandom.urlsafe_base64(16)
    end

    def save
      key = key(token)
      redis.del(key)
      redis.rpush(key, [user_id, app_id, *scopes].map(&:to_s))
      redis.set(reuse_key, token)
    end

    def user
      @user ||= User.find(user_id) if user_id
    end

    def user?
      !!user
    end

    def to_s
      token
    end

    module Helpers
      private
        def redis
          Thread.current[:redis] ||= ::Redis.connect(url: Travis.config.redis.url)
        end

        def key(token)
          "t:#{token}"
        end
    end

    include Helpers
    extend Helpers

    private

      def reuse_token
        redis.get(reuse_key)
      end

      def reuse_key
        @reuse_key ||= begin
          keys = ["r", user_id, app_id]
          keys.append(scopes.map(&:to_s).sort) if scopes != DEFAULT_SCOPES
          keys.join(':')
        end
      end
  end
end
