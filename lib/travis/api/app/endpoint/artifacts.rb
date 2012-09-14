require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Artifacts < Endpoint
      # TODO: Add documentation.
      get('/:id') do |id|
        service(:artifacts).find_one(params)
      end
    end
  end
end
