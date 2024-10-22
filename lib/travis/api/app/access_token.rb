require 'securerandom'

class Travis::Api::App
  class AccessToken
    DEFAULT_SCOPES = [:public, :private]
    attr_reader :token, :travis_token, :scopes, :user_id, :app_id, :expires_in, :extra

    def self.create(options = {})
      new(options).tap(&:save)
    end

    def self.for_travis_token(travis_token, options = {})
      travis_token = Token.find_by_token(travis_token) unless travis_token.respond_to? :user
      new(scope: :travis_token, app_id: 1, user: travis_token.user, travis_token: travis_token).tap(&:save) if travis_token
    end

    def self.find_by_token(token)
      return token if token.is_a? self
      user_id, app_id, *scopes = redis.lrange(key(token), 0, -1)
      extra = decode_json(scopes.pop) if scopes.last && scopes.last =~ /^json:/

      reset_expiry(token, user_id, app_id)

      new(token: token, scopes: scopes, user_id: user_id, app_id: app_id, extra: extra) if user_id
    end

    def initialize(options = {})
      raise ArgumentError, 'must supply either user_id or user' unless options.key?(:user) ^ options.key?(:user_id)
      raise ArgumentError, 'must supply app_id' unless options.key?(:app_id)

      begin
        @expires_in = Integer(options[:expires_in]) if options[:expires_in]
      rescue ArgumentError
        raise ArgumentError, 'expires_in must be of integer type'
      end

      @app_id       = Integer(options[:app_id])
      @scopes       = Array(options[:scopes] || options[:scope] || DEFAULT_SCOPES).map(&:to_sym)
      @user         = options[:user]
      @user_id      = Integer(options[:user_id] || @user.id)
      @token        = options[:token] || (options[:force] ? false : reuse_token) || SecureRandom.urlsafe_base64(16)
      @travis_token = options[:travis_token]
      @extra        = options[:extra]
    end

    def save
      key = key(token)
      redis.del(key)
      data = [user_id, app_id, *scopes]
      data << encode_json(extra) if extra
      redis.rpush(key, data.map(&:to_s))
      redis.set(reuse_key, token)

      if expires_in
        redis.expire(reuse_key, expires_in)
        redis.expire(key, expires_in)
      end
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
          Travis.redis
        end

        def key(token)
          "t:#{token}"
        end

        def encode_json(hash)
          'json:' + Base64.encode64(hash.to_json)
        end

        def decode_json(json)
          JSON.parse(Base64.decode64(json.gsub(/^json:/, '')))
        end
    end

    include Helpers
    extend Helpers

    private

      def reuse_token
        redis.get(reuse_key) unless expires_in
      end

      def reuse_key
        @reuse_key ||= begin
          keys = ["r", user_id, app_id]
          keys.append(scopes.map(&:to_s).sort) if scopes != DEFAULT_SCOPES
          keys.join(':')
        end
      end

      def self.reset_expiry(token, user_id, app_id)
        web_token = Token.find_by(user_id: user_id, purpose: :web)

        if web_token && (token == web_token.token)
          redis.expire(key(token), web_token_expires_in)
        elsif app_id == '1' # This is the TravisCLI token app_id
          redis.expire(key(token), auth_cli_token_expires_in)
          redis.expire("r:#{user_id}:#{app_id}", auth_cli_token_expires_in)
        else
          redis.expire(key(token), auth_token_expires_in)
        end
      end

      def self.web_token_expires_in
        Travis.config.tokens&.web_token.expires_in
      end

      def self.auth_token_expires_in
        Travis.config.tokens&.auth_token.expires_in
      end

      def self.auth_cli_token_expires_in
        Travis.config.tokens&.auth_cli_token.expires_in
      end
  end
end
