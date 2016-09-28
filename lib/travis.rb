require 'pusher'
require 'travis/support'
require 'travis/redis_pool'
require 'travis/support/database'

module Travis
  class << self
    def services=(services)
      @services = services
    end

    def services
      @services ||= Travis::Services
    end
  end

  require 'travis/config/defaults'
  require 'travis/features'
  require 'core_ext/hash/compact'
  require 'travis/settings'
  require 'travis/settings/encrypted_value'

  class UnknownRepository < StandardError; end
  class GithubApiError    < StandardError; end
  class AdminMissing      < StandardError; end
  class RepositoryMissing < StandardError; end
  class LogAlreadyRemoved < StandardError; end
  class AuthorizationDenied < StandardError; end
  class JobUnfinished     < StandardError; end

  class << self
    def setup(options = {})
      @config = Config.load(*options[:configs])
      @redis = Travis::RedisPool.new(config.redis.to_h)

      Travis.logger.info("Setting up module Travis")
    end

    attr_accessor :redis, :config

    def pusher
      @pusher ||= ::Pusher.tap do |pusher|
        pusher.app_id = config.pusher.app_id
        pusher.key    = config.pusher.key
        pusher.secret = config.pusher.secret
        pusher.scheme = config.pusher.scheme if config.pusher.scheme
        pusher.host   = config.pusher.host   if config.pusher.host
        pusher.port   = config.pusher.port   if config.pusher.port
      end
    end

    def states_cache
      @states_cache ||= Travis::StatesCache.new
    end
  end

  setup
end
