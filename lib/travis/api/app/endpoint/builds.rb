require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Builds < Endpoint
      # TODO: Add documentation.
      get '/' do
        service(:builds).find_all(params)
      end

      # TODO: Add documentation.
      get '/:id' do
        service(:builds).find_one(params)
      end
    end
  end
end
