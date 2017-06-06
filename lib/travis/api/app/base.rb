require 'sinatra/base'
require 'mustermann'
require 'travis/api/app'
require 'travis/api/app/extensions'
require 'travis/api/app/helpers'

if ENV['NEW_RELIC_ENABLED'] == 'true' || ENV['NEW_RELIC_ENABLED_FOR_DYNOS'] && ENV['NEW_RELIC_ENABLED_FOR_DYNOS'].split(' ').include?(ENV['DYNO'])
  require 'newrelic_rpm'
end

class Travis::Api::App
  # Superclass for any endpoint and middleware.
  # Pulls in relevant helpers and extensions.
  class Base < Sinatra::Base
    register Extensions::SmartConstants
    register Mustermann

    error NotImplementedError do
      content_type :txt
      status 501
      "This feature has not yet been implemented. Sorry :(\n\nPull Requests welcome!"
    end

    error JSON::ParserError do
      status 400
      "Invalid JSON in request body"
    end

    # hotfix??
    def route_missing
      @app ? forward : halt(404)
    end

    def call(env)
      super
    rescue Sinatra::NotFound
      [404, {'Content-Type' => 'text/plain'}, ['Tell Konstantin to fix this!']]
    end

    configure do
      # We pull in certain protection middleware in App.
      # Being token based makes us invulnerable to common
      # CSRF attack.
      #
      # Logging is set up by custom middleware
      disable  :protection, :logging, :setup
      enable   :raise_errors
      disable  :dump_errors
      register :subclass_tracker, :expose_pattern
      helpers  :respond_with, :mime_types
    end

    configure :development do
      # We want error pages in development, but only
      # when we don't have an error handler specified
      set :show_exceptions, :after_handler
      enable :dump_errors
    end
  end
end
