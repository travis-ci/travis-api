require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Accounts < Endpoint
      get '/', scope: :private do
        respond_with all(params).run, type: :accounts
      end
    end
  end
end
