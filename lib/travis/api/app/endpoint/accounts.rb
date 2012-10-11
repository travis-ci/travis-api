require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Accounts < Endpoint
      get '/', scope: :private do
        respond_with service(:accounts, :find_all, params), type: :accounts
      end
    end
  end
end
