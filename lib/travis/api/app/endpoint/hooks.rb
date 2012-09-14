require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Hooks < Endpoint
      # TODO: Add implementation and documentation.
      get('/', scope: :private) do
        service(:builds).find_all(params)
      end

      # TODO: Add implementation and documentation.
      put('/:id', scope: :admin) do
        respond_with service(:hooks).update(params)
      end
    end
  end
end
