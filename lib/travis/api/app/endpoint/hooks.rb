require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Hooks < Endpoint
      # TODO: Add implementation and documentation.
      get('/', scope: :private) { raise NotImplementedError }

      # TODO: Add implementation and documentation.
      put('/:id', scope: :admin) { raise NotImplementedError }
    end
  end
end
