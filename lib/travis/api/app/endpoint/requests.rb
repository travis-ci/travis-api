require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      post '/' do
        respond_with service(:requeue_request, params)
      end
    end
  end
end

