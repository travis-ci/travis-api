require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        respond_with service(:builds, :find_all, params)
      end

      get '/:id' do
        respond_with service(:builds, :find_one, params)
      end
    end
  end
end
