require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      # DEPRECATED: this will be removed by 1st of December
      post '/' do
        Metriks.meter("api.request.restart").mark
        respond_with service(:reset_model, params)
      end

      get '/' do
        begin
          respond_with(service(:find_requests, params).run)
        rescue Travis::RepositoryNotFoundError => e
          status 404
          { "error" => "Repository could not be found" }
        end
      end

      get '/:id' do
        respond_with service(:find_request, params)
      end
    end
  end
end

