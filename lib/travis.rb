require 'pusher'
require 'travis/support'
require 'travis/support/database'
require 'travis/redis_pool'
require 'travis/errors'

module Travis
  class << self
    attr_accessor :testing

    def services=(services)
      @services = services
    end

    def services
      @services ||= Travis::Services
    end
  end

  require 'travis/model'
  require 'travis/task'
  require 'travis/event'
  require 'travis/api/serialize'
  require 'travis/config/defaults'
  require 'travis/features'
  require 'travis/github'
  require 'travis/notification'
  require 'travis/services'

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

      Github.setup
      Services.register
      Github::Services.register
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
