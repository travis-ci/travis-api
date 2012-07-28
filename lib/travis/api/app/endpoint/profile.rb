require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Profile < Endpoint
      # TODO: Add implementation and documentation.
      get('/', scope: :private) { raise NotImplementedError }

      # TODO: Add implementation and documentation.
      post('/sync', scope: :private) { raise NotImplementedError }
    end
  end
end
