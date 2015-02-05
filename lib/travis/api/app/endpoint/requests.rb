require 'travis/api/app'
require 'travis/api/app/services/schedule_request'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      post '/', scope: :private do
        respond_with service(:schedule_request, params[:request])
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

