require 'travis/api/app'
require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'
require 'travis/api/app/responders/base'

class Travis::Api::App
  class Endpoint
    class Logout < Endpoint
      before { authenticate_by_mode! }

      get '/' do
        respond_with current_user if Travis.redis.del("t:#{access_control.token}") == 1
      end
    end
  end
end
