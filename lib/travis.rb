require 'pusher'
require 'travis/support'
#require 'travis/support/database'
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
  class LogExpired        < StandardError; end
  class LogAccessDenied   < StandardError; end
  class AuthorizationDenied < StandardError; end
  class JobUnfinished     < StandardError; end

  class << self
    attr_accessor :config

    def setup(options = {})
      @config = Config.load(*options[:configs])

      Travis.logger.info("Setting up module Travis")

      Github.setup
      Services.register
      Github::Services.register

      require 'patches/active_record/predicate_builder'
    end

    def redis
      cfg = config.redis.to_h
      cfg = cfg.merge(ssl_params: redis_ssl_params) if config.redis.ssl
      @redis ||= Redis.new(cfg.to_h)
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

    def redis_ssl_params
      @redis_ssl_params ||= begin
        return nil unless Travis.config.redis.ssl

        value = {}
        value[:ca_file] = ENV['REDIS_SSL_CA_FILE'] if ENV['REDIS_SSL_CA_FILE']
        value[:cert] = OpenSSL::X509::Certificate.new(File.read(ENV['REDIS_SSL_CERT_FILE'])) if ENV['REDIS_SSL_CERT_FILE']
        value[:key] = OpenSSL::PKEY::RSA.new(File.read(ENV['REDIS_SSL_KEY_FILE'])) if ENV['REDIS_SSL_KEY_FILE']
        value[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if Travis.config.ssl_verify == false
        value
      end
    end

    def states_cache
      @states_cache ||= Travis::StatesCache.new
    end
  end

  setup
end
