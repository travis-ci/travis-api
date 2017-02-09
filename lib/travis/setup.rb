require 'pusher'
require 'fileutils'
require 'securerandom'
require 'travis/support'
require 'travis/redis_pool'
require 'travis/config/defaults'
require 'travis/settings'
require 'travis/settings/encrypted_value'
require 'core_ext/hash/compact'

module Travis
  module Setup
    attr_reader :redis, :config

    require 'travis/setup/database_connections'
    require 'travis/setup/monitoring'
    require 'travis/setup/sidekiq'
    require 'travis/setup/support'

    private def setup
      @config = Config.load
      @redis  = Travis::RedisPool.new(config.redis.to_h)

      Support.setup
      DatabaseConnections.setup
      Monitoring.setup
      Sidekiq.setup

      FileUtils.touch('/tmp/app-initialized') if Travis.heroku?
    end

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

    def production?
      Travis.env == 'production'.freeze or Travis.env == 'staging'.freeze
    end

    def heroku?
      !!ENV['DYNO']
    end
  end

  extend Setup
  setup
end
