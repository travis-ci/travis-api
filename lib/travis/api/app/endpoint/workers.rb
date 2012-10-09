require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Workers < Endpoint
      get '/' do
        respond_with all(params)
      end

      get '/:id' do
        respond_with one(params)
      end
    end
  end
end
