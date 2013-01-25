require 'travis/api/app'
require 'sinatra/base'
#require 'new_relic/agent/instrumentation/rack'

class Travis::Api::App
  # Superclass for any endpoint and middleware.
  # Pulls in relevant helpers and extensions.
  class Base < Sinatra::Base
    register Extensions::SmartConstants

    configure :production do
      #require 'newrelic_rpm'
    end

    error NotImplementedError do
      content_type :txt
      status 501
      "This feature has not yet been implemented. Sorry :(\n\nPull Requests welcome!"
    end

    configure do
      # We pull in certain protection middleware in App.
      # Being token based makes us invulnerable to common
      # CSRF attack.
      #
      # Logging is set up by custom middleware
      disable  :protection, :logging, :setup
      enable   :raise_errors
      # disable  :dump_errors
      register :subclass_tracker
      helpers  :respond_with, :mime_types
    end

    configure :development do
      # We want error pages in development, but only
      # when we don't have an error handler specified
      set :show_exceptions, :after_handler
    end
  end
end
