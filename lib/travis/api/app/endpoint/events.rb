require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Events < Endpoint
      get '/' do
        respond_with service(:find_events, params), type: :events
      end
    end
  end
end

