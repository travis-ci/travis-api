require 'travis/api/app'
require 'travis/api/app/services/schedule_request'
require 'travis/api/enqueue/services/restart_model'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      get '/' do
        begin
          respond_with(service(:find_requests, params).run)
        rescue RepositoryNotFoundError => e
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
          #
          # TODO It seems this endpoint is still in use, quite a bit:
          # https://metrics.librato.com/s/metrics/api.request.restart?duration=2419200&q=api.request.restart
          #
          # I think we need to properly deprecate this by publishing a blog post.
          Metriks.meter("api.request.restart").mark
          service = Travis::Enqueue::Services::RestartModel.new(current_user, params)
          params[:user_id] = service.target.repository.owner.id

          type = params[:build_id] ? 'build' : 'job'
          params[:id] = params[:build_id] || params[:job_id]

          service.push("#{type}:restart", params)
          respond_with(result: true, flash: service.messages)
        end
      end
    end
  end
end
