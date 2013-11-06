require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      # DEPRECATED: this will be removed by 1st of December
      post '/' do
        Metriks.meter("api.request.restart").mark
        respond_with service(:reset_model, params)
      end
    end
  end
end

