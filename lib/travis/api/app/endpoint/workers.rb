require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Workers < Endpoint
      get '/' do
        respond_with service(:workers, :find_all, params)
      end

      get '/:id' do
        respond_with service(:workers, :find_one, params)
      end
    end
  end
end
