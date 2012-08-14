# Make sure we set that before everything
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || ENV['ENV']
ENV['RAILS_ENV']  = ENV['RACK_ENV']

require 'travis'
require 'backports'
require 'rack'
require 'rack/protection'
require 'active_record'
require 'redis'
require 'gh'

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
    return if setup?
    Travis::Database.connect

    Responder.set(options) if options
    Backports.require_relative_dir 'app/middleware'
    Backports.require_relative_dir 'app/endpoint'
    Responder.subclasses.each(&:setup)

    @setup = true
  end

  attr_accessor :app

  def initialize(options = {})
    Travis::Api::App.setup
    @app = Rack::Builder.app do
      use Rack::Protection::PathTraversal
      use Rack::SSL if Endpoint.production?
      use ActiveRecord::ConnectionAdapters::ConnectionManagement
      Middleware.subclasses.each { |m| use(m) }
      endpoints = Endpoint.subclasses
      endpoints -= [Endpoint::Home] if options[:disable_root_endpoint]
      endpoints.each { |e| map(e.prefix) { run(e.new) } }
    end
  end

  # Rack protocol
  def call(env)
    app.call(env)
  end
end
