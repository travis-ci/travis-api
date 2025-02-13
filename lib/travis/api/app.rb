# now actually load travis
require 'travis'
require 'travis/amqp'
require 'travis/model'
require 'travis/states_cache'
require 'travis/request_deadline'
require 'travis/honeycomb'
require 'travis/marginalia'
require 'rack'
require 'rack/protection'
require 'rack/contrib/config'
require 'rack/contrib/jsonp'
require 'rack/contrib/json_body_parser'
require 'rack/contrib/post_body_content_type_parser'
require 'dalli'
require 'rack/cache'
require 'travis/api/attack'
require 'active_record'
require 'redis'
require 'gh'
require 'sidekiq'
require 'connection_pool'
require 'metriks/reporter/logger'
require 'metriks/librato_metrics_reporter'
require 'travis/support/log_subscriber/active_record_metrics'
require 'fileutils'
require 'securerandom'
require 'rbtrace'

module Travis::Api
end

require 'travis/api/app/endpoint'
require 'travis/api/app/middleware'
require 'travis/api/serialize/v2'
require 'travis/api/v3'
require 'travis/api/app/error_handling'
require 'travis/api/sidekiq'
require 'travis/support/database'

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


    def self.deploy_sha
      @deploy_sha ||= ENV['HEROKU_SLUG_COMMIT'] || SecureRandom.hex(5)
    end

    attr_accessor :app

    def initialize(options = {})
      self.class.setup(options)
      @app = Rack::Builder.app do
        # if stackprof = ENV['STACKPROF']
        #   require 'stackprof'
        #   modes = ['wall', 'cpu', 'object', 'custom']
        #   mode  = modes.include?(stackprof) ? stackprof.to_sym : :cpu
        #   Travis.logger.info "Setting up profiler: #{mode}"
        #   use StackProf::Middleware, enabled: true, save_every: 1, mode: mode
        # end

        use Travis::RequestDeadline::Middleware if Travis::RequestDeadline.enabled?

        use Rack::Config do |env|
          env['metriks.request.start'] ||= Time.now.utc

          Travis::Honeycomb.clear
          Travis::Honeycomb.context.add('request_id', env['HTTP_X_REQUEST_ID'])

          ::Marginalia.clear!
          ::Marginalia.set('app', 'api')
          ::Marginalia.set('request_id', env['HTTP_X_REQUEST_ID'])
        end

        use Travis::Api::App::Cors
        use Travis::Api::App::Middleware::RequestId
        use Travis::Api::App::Middleware::ErrorHandler

        # puts "is it enterprise? #{Travis::Api::App.enterprise?}"
        if Travis::Api::App.use_monitoring?
          use Rack::Config do |env|
            if env['HTTP_X_REQUEST_ID']
              Sentry.with_scope do |scope|
                scope.set_tags(request_id: env['HTTP_X_REQUEST_ID']) unless Travis::Api::App.enterprise?
              end
            end
          end
          use Sentry::Rack::CaptureExceptions
        end

        if Travis::Honeycomb.api_requests.enabled?
          use Travis::Api::App::Middleware::Honeycomb
        end

        if Travis::Api::App::Middleware::LogTracing.enabled?
          use Travis::Api::App::Middleware::LogTracing
        end

        if Travis::Api::App::Middleware::OpenCensus.enabled?
          use Travis::Api::App::Middleware::OpenCensus
        end

        use Rack::SSL if Endpoint.production? && !ENV['DOCKER']
        use ConnectionManagement

        memcache_servers = ENV['MEMCACHIER_SERVERS']
        if Travis::Features.feature_active?(:use_rack_cache) && memcache_servers
          use Rack::Cache,
            metastore:   "memcached://#{memcache_servers}/meta-#{Travis::Api::App.deploy_sha}",
            entitystore: "memcached://#{memcache_servers}/body-#{Travis::Api::App.deploy_sha}"
        end

        use Rack::Deflater
        use Rack::JSONBodyParser
        use Rack::JSONP

        use Rack::Config do |env|
          env['SCRIPT_NAME'] = env['HTTP_X_SCRIPT_NAME'].to_s + env['SCRIPT_NAME'].to_s
          env['travis.global_prefix'] = env['SCRIPT_NAME']
        end

        use Travis::Api::App::Middleware::Logging
        use Travis::Api::App::Middleware::ScopeCheck
        use Travis::Api::App::Middleware::UserAgentTracker

        # make sure this is below ScopeCheck so we have the token
        use Rack::Attack unless Endpoint.development? || Endpoint.test? || Travis.config.enterprise

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
          next if e == SettingsEndpoint # TODO: add something like abstract? method to check if class should be registered
          map(e.prefix) { run e }
        end
      end
    end

    # Rack protocol
    def call(env)
      #app.after { ActiveRecord::Base.clear_active_connections! }
      app.call(env)
    rescue => e
      # puts("Debug error 'app.call': #{e.message}")
      # puts("Backtrace:\n\t#{e.backtrace.join("\n\t")}")
      if Endpoint.production?
        [500, {'Content-Type' => 'application/json'}, [ERROR_RESPONSE]]
      else
        raise
      end
    end

    private

      def self.enterprise?
        !!Travis.config.enterprise
      end

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

        Sidekiq.configure_client do |config|
          cfg = Travis.config.redis.to_h
          cfg = cfg.merge(ssl_params: Travis.redis_ssl_params) if Travis.config.redis.ssl && Travis.redis_ssl_params
          config.redis = cfg
        end

        if use_monitoring? && !console?
          setup_monitoring
        end

        Travis::RequestDeadline.setup
      end

      def self.setup_database_connections
        if ENV['QUERY_COMMENTS_ENABLED'] == 'true'
          Travis::Marginalia.setup
        end

        if Travis::Api::App::Middleware::LogTracing.enabled?
          Travis::Api::App::Middleware::LogTracing.setup
        end
        if Travis::Api::App::Middleware::OpenCensus.enabled?
          Travis::Api::App::Middleware::OpenCensus.setup
        end


        if ENV['MODEL_RENDERER_TRACING_ENABLED'] == 'true'
          Travis::API::V3::ModelRenderer.install_tracer
        end

        Travis.config.database.variables                    ||= {}
        Travis.config.database.variables[:application_name] ||= ["api", Travis.env, ENV['DYNO']].compact.join(?-)
        Travis::Database.connect
      end

      def self.setup_monitoring
        Travis::Api::App::ErrorHandling.setup

        Travis::Honeycomb::Context.add_permanent('app', 'api')
        Travis::Honeycomb::Context.add_permanent('dyno', ENV['DYNO'])
        Travis::Honeycomb::Context.add_permanent('site', ENV['TRAVIS_SITE'])
        Travis::Honeycomb.setup

        Travis::LogSubscriber::ActiveRecordMetrics.attach
        Travis::Notification.setup(instrumentation: false)
      end

      def self.setup_endpoints
        Base.subclasses.each(&:setup)
      end
  end

  class ConnectionManagement
    def initialize(app)
      @app = app
    end

    def call(env)
      testing = ENV['RACK_ENV'] == 'test'

      status, headers, body = @app.call(env)
      proxy = ::Rack::BodyProxy.new(body) do
        ActiveRecord::Base.clear_active_connections! unless testing
      end
      [status, headers, proxy]
    rescue Exception
      ActiveRecord::Base.clear_active_connections! unless testing
      raise
    end
  end
end
