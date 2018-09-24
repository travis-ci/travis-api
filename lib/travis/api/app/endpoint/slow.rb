require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Slow < Endpoint
      if ENV['SLOW_ENDPOINT_ENABLED'] == 'true'
        get '/' do
          sleep 60
        end
      end
    end
  end
end
