require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Broadcasts < Endpoint
      get '/', scope: :private do
        respond_with service(:users, :find_broadcasts, params), type: :broadcasts
      end
    end
  end
end
