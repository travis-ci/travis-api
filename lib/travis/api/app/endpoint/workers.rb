require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Workers < Endpoint
      # TODO: Add implementation and documentation.
      get('/') { Worker.order(:host, :name) }
    end
  end
end
