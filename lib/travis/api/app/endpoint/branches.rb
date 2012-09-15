require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Branches < Endpoint
      # TODO: Add documentation.
      get('/') do
        body service(:branches).find_all(params), :type => :branches
      end
    end
  end
end
