require 'travis/api/app'
require 'securerandom'

class Travis::Api::App
  class AccessToken
    DEFAULT_SCOPES = [:public, :private]
    attr_reader :token, :scopes, :user_id

    def self.create(options = {})
      new(options).tap(&:save)
    end

    def self.find_by_token(token)
      user_id, app_id, *scopes = redis.lrange(key(token), 0, -1)
      new(token: token, scopes: scopes, user_id: user_id) if user_id
    end

    def initialize(options = {})
      raise ArgumentError, 'must supply either user_id or user' unless options.key?(:user) ^ options.key?(:user_id)

      @token    = options[:token] || SecureRandom.urlsafe_base64(64)
      @scopes   = Array(options[:scopes] || options[:scope] || DEFAULT_SCOPES).map(&:to_sym)
      @user     = options[:user]
      @user_id  = Integer(options[:user_id] || @user.id)
    end

    def save
      key = key(token)
      redis.del(key)
      redis.rpush(key, [user_id, '', *scopes].map(&:to_s))
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
  end
end
