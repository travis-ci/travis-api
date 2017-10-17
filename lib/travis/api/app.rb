# these things need to go first
require 'conditional_skylight'
require 'active_record_postgres_variables'

# now actually load travis
require 'travis'
require 'travis/amqp'
require 'travis/model'
require 'travis/states_cache'
require 'travis/honeycomb'
require 'rack'
require 'rack/protection'
require 'rack/contrib/config'
require 'rack/contrib/jsonp'
require 'rack/contrib/post_body_content_type_parser'
require 'dalli'
require 'memcachier'
require 'rack/cache'
require 'travis/api/attack'
require 'active_record'
require 'redis'
require 'gh'
require 'raven'
require 'raven/integrations/rack'
require 'sidekiq'
require 'metriks/reporter/logger'
require 'metriks/librato_metrics_reporter'
require 'travis/support/log_subscriber/active_record_metrics'
require 'fileutils'
require 'securerandom'
require 'fog/aws'

module Travis::Api
end

require 'travis/api/app/endpoint'
require 'travis/api/app/middleware'
require 'travis/api/instruments'
require 'travis/api/serialize/v2'
require 'travis/api/v3'
require 'travis/api/app/stack_instrumentation'
require 'travis/api/app/error_handling'
require 'travis/api/sidekiq'

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

    ERROR_RESPONSE = JSON.generate(error: 'Travis encountered an error, sorry :(')

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
      FileUtils.touch('/tmp/app-initialized') if ENV['DYNO'] # Heroku
    end

    def self.new(options = {})
      setup(options)
      super()
    end

    def self.deploy_sha
      @deploy_sha ||= ENV['HEROKU_SLUG_COMMIT'] || SecureRandom.hex(5)
    end

    attr_accessor :app

    def initialize
      @app = Rack::Builder.app do
        # if stackprof = ENV['STACKPROF']
        #   require 'stackprof'
        #   modes = ['wall', 'cpu', 'object', 'custom']
        #   mode  = modes.include?(stackprof) ? stackprof.to_sym : :cpu
        #   Travis.logger.info "Setting up profiler: #{mode}"
        #   use StackProf::Middleware, enabled: true, save_every: 1, mode: mode
        # end

        use Rack::Config do |env|
          env['metriks.request.start'] ||= Time.now.utc

          Travis::Honeycomb.clear
          Travis::Honeycomb.context.add('x_request_id', env['HTTP_X_REQUEST_ID'])
        end

        use Travis::Api::App::Middleware::RequestId
        use Travis::Api::App::Middleware::ErrorHandler

        extend StackInstrumentation
        use Travis::Api::App::Middleware::Skylight

        use Rack::Config do |env|
          if env['HTTP_HONEYCOMB_OVERRIDE'] == 'true'
            Travis::Honeycomb.override!
          end
        end

        if Travis::Honeycomb.api_requests.enabled?
          use Travis::Api::App::Middleware::Honeycomb
        end

        use Travis::Api::App::Cors # if Travis.env == 'development' ???
        if Travis::Api::App.use_monitoring?
          use Rack::Config do |env|
            if env['HTTP_X_REQUEST_ID']
              Raven.tags_context(x_request_id: env['HTTP_X_REQUEST_ID'])
            end
          end
          use Raven::Rack
        end
        use Rack::SSL if Endpoint.production?
        use ActiveRecord::ConnectionAdapters::ConnectionManagement
        use ActiveRecord::QueryCache

        memcache_servers = ENV['MEMCACHIER_SERVERS']
        if Travis::Features.feature_active?(:use_rack_cache) && memcache_servers
          use Rack::Cache,
            metastore:   "memcached://#{memcache_servers}/meta-#{Travis::Api::App.deploy_sha}",
            entitystore: "memcached://#{memcache_servers}/body-#{Travis::Api::App.deploy_sha}"
        end

        use Rack::Deflater
        use Rack::PostBodyContentTypeParser
        use Rack::JSONP

        use Rack::Config do |env|
          env['SCRIPT_NAME'] = env['HTTP_X_SCRIPT_NAME'].to_s + env['SCRIPT_NAME'].to_s
          env['travis.global_prefix'] = env['SCRIPT_NAME']
        end

        use Travis::Api::App::Middleware::Logging
        use Travis::Api::App::Middleware::ScopeCheck
        use Travis::Api::App::Middleware::UserAgentTracker

        use Rack::Config do |env|
          if ENV['TRAVIS_DEBUG_USER_LOGIN'] && ENV['TRAVIS_DEBUG_USER_LOGIN'] == env['travis.access_token']&.user&.login
            puts "debug: #{ENV['TRAVIS_DEBUG_USER_LOGIN']} #{env}"
          end
        end

        # make sure this is below ScopeCheck so we have the token
        use Rack::Attack if Endpoint.production? and not Travis.config.enterprise

        # if this is a v3 API request, ignore everything after
        use Travis::API::V3::OptIn

        # rewrite should come after V3 hook
        use Travis::Api::App::Middleware::Rewrite

        # v3 has its own metriks
        use Travis::Api::App::Middleware::Metriks

        SettingsEndpoint.subclass :env_vars
        if Travis.config.endpoints.ssh_key
          SingletonSettingsEndpoint.subclass :ssh_key
        end

        Endpoint.subclasses.each do |e|
          next if e == SettingsEndpoint # TODO: add something like abstract? method to check if
                                        # class should be registered
          map(e.prefix) { run(e.new) }
        end
      end
    end

    # Rack protocol
    def call(env)
      app.call(env)
    rescue
      if Endpoint.production?
        [500, {'Content-Type' => 'application/json'}, [ERROR_RESPONSE]]
      else
        raise
      end
    end

    private

      def self.console?
        defined? Travis::Console
      end

      def self.use_monitoring?
        Travis.env == 'production' || Travis.env == 'staging'
      end

      def self.setup!
        setup_travis
        setup_endpoints
        @setup = true
      end

      def self.setup_travis
        Travis::Async.enabled = true
        Travis::Amqp.setup(Travis.config.amqp.to_h)

        setup_database_connections

        if use_monitoring?
          Sidekiq.configure_client do |config|
            config.redis = Travis.config.redis.to_h.merge(size: 1, namespace: Travis.config.sidekiq.namespace)
          end
        end

        if use_monitoring? && !console?
          setup_monitoring
        end

        if defined?(Fog) && defined?(Fog::Logger)
          %i(warning deprecation debug).each do |channel|
            Fog::Logger[channel] = nil
          end
        end
      end

      def self.setup_database_connections
        Travis.config.database.variables                    ||= {}
        Travis.config.database.variables[:application_name] ||= ["api", Travis.env, ENV['DYNO']].compact.join(?-)
        Travis::Database.connect
      end

      def self.setup_monitoring
        Travis::Api::App::ErrorHandling.setup

        Travis::Honeycomb.setup

        Travis::LogSubscriber::ActiveRecordMetrics.attach
        Travis::Notification.setup(instrumentation: false)
        Travis::Metrics.setup
      end

      def self.setup_endpoints
        Base.subclasses.each(&:setup)
      end
  end
end
