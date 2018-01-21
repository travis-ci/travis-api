require 'travis/api/app'

class Travis::Api::App
  # Superclass for all middleware.
  class Middleware < Base
    require 'travis/api/app/middleware/error_handler'
    require 'travis/api/app/middleware/logging'
    require 'travis/api/app/middleware/metriks'
    require 'travis/api/app/middleware/rewrite'
    require 'travis/api/app/middleware/request_id'
    require 'travis/api/app/middleware/scope_check'
    require 'travis/api/app/middleware/honeycomb'
    require 'travis/api/app/middleware/log_tracing'
    require 'travis/api/app/middleware/user_agent_tracker'
  end
end
