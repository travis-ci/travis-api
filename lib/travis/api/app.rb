# Make sure we set that before everything
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || ENV['ENV']
ENV['RAILS_ENV']  = ENV['RACK_ENV']

require 'travis'
require 'backports'
require 'rack'
require 'rack/protection'
require 'rack/contrib'
require 'active_record'
require 'redis'
require 'gh'
require 'hubble'
require 'hubble/middleware'
require 'newrelic_rpm'

# Rack class implementing the HTTP API.
# Instances respond to #call.
#
#     run Travis::Api::App.new
#
# Requires TLS in production.
class Travis::Api::App
  autoload :AccessToken,  'travis/api/app/access_token'
  autoload :Responder,    'travis/api/app/responder'
  autoload :Endpoint,     'travis/api/app/endpoint'
  autoload :Extensions,   'travis/api/app/extensions'
  autoload :Helpers,      'travis/api/app/helpers'
  autoload :Middleware,   'travis/api/app/middleware'

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
    Endpoint.set(options)
  end

  def self.new(options = {})
    setup(options) if options
    super()
  end

  attr_accessor :app

  def initialize
    @app = Rack::Builder.app do
      use Hubble::Rescuer, env: Travis.env, codename: ENV['CODENAME'] if Endpoint.production? && ENV['HUBBLE_ENDPOINT']
      use Rack::Protection::PathTraversal
      use Rack::SSL if Endpoint.production?
      use Rack::PostBodyContentTypeParser
      use Rack::JSONP
      use ActiveRecord::ConnectionAdapters::ConnectionManagement

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
  end

  private

    def self.setup!
      setup_travis
      load_endpoints
      setup_endpoints
      @setup = true
    end

    def self.setup_travis
      Travis::Amqp.config = Travis.config.amqp
      Travis::Database.connect
      # Travis::Services.namespace = Travis::Services
    end

    def self.load_endpoints
      Backports.require_relative_dir 'app/middleware'
      Backports.require_relative_dir 'app/endpoint'
    end

    def self.setup_endpoints
      Responder.subclasses.each(&:setup)
    end
end
