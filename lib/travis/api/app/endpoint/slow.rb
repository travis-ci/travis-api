require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Slow < Endpoint
      if ENV['SLOW_ENDPOINT_ENABLED'] == 'true'
        get '/' do
          60.times do
            if Travis::RequestDeadline.enabled?
              Travis::RequestDeadline.check!
            end
            sleep 1
          end
        end
      end
    end
  end
end
