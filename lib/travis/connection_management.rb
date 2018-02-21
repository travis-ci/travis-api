require 'active_record/base'
require 'rack/body_proxy'

# Replacement for ConnectionManagement middleware
# which was removed from Rails 5.
#
# Implementation cribbed from
# https://github.com/ioquatix/activerecord-rack/blob/v1.0.0/lib/active_record/rack/connection_management.rb
# https://stackoverflow.com/a/43873756
class ConnectionManagement
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    proxy = Rack::BodyProxy.new(body) do
      ActiveRecord::Base.clear_active_connections!
    end
    [status, headers, proxy]
  rescue Exception
    ActiveRecord::Base.clear_active_connections!
    raise
  end
end
