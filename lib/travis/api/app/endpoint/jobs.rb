require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Jobs < Endpoint
      get '/' do
        respond_with service(:jobs, :find_all, params)
      end

      get '/:id' do
        respond_with service(:jobs, :find_one, params)
      end
    end
  end
end
