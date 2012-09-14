require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Workers < Endpoint
      # TODO: Add implementation and documentation.
      get('/') do
        service(:workers).find_all(params)
      end
    end
  end
end
