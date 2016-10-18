module Travis
  class AccessToken
    DEFAULT_SCOPES = [:public, :private]
    attr_reader :app_id, :scopes, :token, :user

    def self.create(options = {})
      new(options).tap(&:save)
    end

    def initialize(options = {})
      raise ArgumentError, 'must supply user' unless options.key?(:user)
      raise ArgumentError, 'must supply app_id' unless options.key?(:app_id)

      @app_id = Integer(options[:app_id])
      @scopes = Array(DEFAULT_SCOPES).map(&:to_sym)
      @user   = options[:user]
      @token  = reuse_token || SecureRandom.urlsafe_base64(16)
    end

    def save
      key = key(token)
      redis.del(key)
      data = [user.id, app_id, *scopes]
      redis.rpush(key, data.map(&:to_s))
      redis.set(reuse_key, token)
    end

    def to_s
      token
    end

    private

    def redis
      Travis::DataStores.redis
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

    def reuse_token
      redis.get(reuse_key)
    end

    def reuse_key
      @reuse_key ||= ["r", user.id, app_id].join(':')
    end
  end
end
