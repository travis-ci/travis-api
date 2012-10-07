require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      post '/' do
        service(:requests, :requeue, params).run
        204
      end
    end
  end
end

