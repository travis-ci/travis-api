require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Branches < Endpoint
      get '/' do
        body all(params).run, type: :branches
      end
    end
  end
end
