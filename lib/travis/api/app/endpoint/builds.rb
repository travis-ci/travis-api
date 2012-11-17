require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        respond_with service(:find_builds, params)
      end

      get '/:id' do
        respond_with service(:find_build, params)
      end
    end
  end
end
