require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Events < Endpoint
      get '/' do
        respond_with service(:events, :find_all, params), type: :events
      end
    end
  end
end

