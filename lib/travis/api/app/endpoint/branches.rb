require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Branches < Endpoint
      # TODO: Add better implementation and documentation.
      get('/') {{ branches: [] }}
    end
  end
end
