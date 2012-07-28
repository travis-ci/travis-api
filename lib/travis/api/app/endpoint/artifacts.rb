require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Artifacts < Endpoint
      # TODO: Add documentation.
      get('/:id') { |id| Artifact.find(id) }
    end
  end
end
