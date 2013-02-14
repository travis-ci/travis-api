require 'travis'
require 'backports'
require 'rack'
require 'rack/protection'
require 'rack/contrib'
require 'rack/cache'
require 'active_record'
require 'redis'
require 'gh'
require 'raven'
require 'sidekiq'
require 'metriks/reporter/logger'
require 'travis/support/log_subscriber/active_record_metrics'

# Rack class implementing the HTTP API.
# Instances respond to #call.
#
#     run Travis::Api::App.new
#
# Requires TLS in production.
module Travis::Api
  class App
    autoload :AccessToken,  'travis/api/app/access_token'
    autoload :Base,         'travis/api/app/base'
    autoload :Endpoint,     'travis/api/app/endpoint'
    autoload :Extensions,   'travis/api/app/extensions'
    autoload :Helpers,      'travis/api/app/helpers'
    autoload :Middleware,   'travis/api/app/middleware'
    autoload :Responders,   'travis/api/app/responders'
    autoload :Cors,         'travis/api/app/cors'

    Rack.autoload :SSL, 'rack/ssl'

    # Used to track if setup already ran.
    def self.setup?
      @setup ||= false
    end

    # Loads all endpoints and middleware and hooks them up properly.
    # Calls #setup on any middleware and endpoint.
    #
    # This method is not threadsafe, but called when loading
    # the environment, so no biggy.
    def self.setup(options = {})
      setup! unless setup?
      Endpoint.set(options) if options
    end

    def self.new(options = {})
      setup(options)
      super()
    end

    def self.deploy_sha
      @deploy_sha ||= File.exist?('.deploy_sha') ? File.read('.deploy-sha')[0..7] : 'deploy-sha'
    end

    attr_accessor :app

    def initialize
      @app = Rack::Builder.app do
        use Travis::Api::App::Cors
        use Raven::Rack if Endpoint.production?
        use Rack::Protection::PathTraversal
        use Rack::SSL if Endpoint.production?
        use ActiveRecord::ConnectionAdapters::ConnectionManagement
        use ActiveRecord::QueryCache

        memcache_servers = ENV['MEMCACHE_SERVERS']
        if Travis::Features.feature_active?(:use_rack_cache) && memcache_server
          use Rack::Cache,
            verbose: true,
            metastore:   "memcached://#{memcache_servers}/#{self.class.deploy_sha}",
            entitystore: "memcached://#{memcache_servers}/#{self.class.deploy_sha}"
        end

        use Rack::Deflater
        use Rack::PostBodyContentTypeParser
        use Rack::JSONP

        use Rack::Config do |env|
          env['travis.global_prefix'] = env['SCRIPT_NAME']
        end

        Middleware.subclasses.each { |m| use(m) }
        Endpoint.subclasses.each { |e| map(e.prefix) { run(e.new) } }
      end
    end

    # Rack protocol
    def call(env)
      app.call(env)
    rescue
      if Endpoint.production?
        [500, {'Content-Type' => 'text/plain'}, ['Travis encountered an error, sorry :(']]
      else
        raise
      end
    end

    private

      def self.console?
        defined? Travis::Console
      end

      def self.setup!
        setup_travis
        load_endpoints
        setup_endpoints
        @setup = true
      end

      def self.setup_travis
        Travis::Amqp.config = Travis.config.amqp
        Travis::Database.connect
        Travis::Features.start

        if Travis.env == 'production' || Travis.env == 'staging'
          Sidekiq.configure_client do |config|
            config.redis = Travis.config.redis.merge(size: 1, namespace: Travis.config.sidekiq.namespace)
          end
        end

        if Travis.env == 'production' and not console?
          Raven.configure do |config|
            config.dsn = Travis.config.sentry.dsn
          end if Travis.config.sentry

          Travis::LogSubscriber::ActiveRecordMetrics.attach
          Travis::Notification.setup
        end
      end

      def self.load_endpoints
        Backports.require_relative_dir 'app/middleware'
        Backports.require_relative_dir 'app/endpoint'
      end

      def self.setup_endpoints
        Base.subclasses.each(&:setup)
      end
  end
end
