require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Hooks < Endpoint
      # TODO: Add implementation and documentation.
      get('/', scope: :private) do
        body service(:hooks).find_all(params), type: :hooks
      end

      # TODO: Add implementation and documentation.
      put('/:id', scope: :private) do
        body service(:hooks).update(params[:hook])
      end
    end
  end
end
