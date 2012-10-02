require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Workers < Endpoint
      get '/' do
        body all(params).run
      end
    end
  end
end
