require 'travis/api/app'
require 'travis/api/app/services/schedule_request'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
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

      post '/', scope: :private do
        if params[:request] && params[:request][:repository]
          status 404
        else
          # DEPRECATED: this will be removed by 1st of December
          Metriks.meter("api.request.restart").mark
          respond_with service(:reset_model, params)
        end
      end
    end
  end
end

