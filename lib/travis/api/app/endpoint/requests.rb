require 'travis/api/app'
require 'travis/api/app/services/schedule_request'
require 'travis/api/enqueue/services/restart_model'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      before { authenticate_by_mode! }

      get '/' do
        begin
          respond_with(service(:find_requests, params).run)
        rescue Travis::RepositoryNotFoundError => e
          status 404
          { "error" => "Repository could not be found" }
        end
      end

      get '/:id' do
        respond_with service(:find_request, params), type: :request
      end

      post '/', scope: :private do
        if params[:request] && params[:request][:repository]
          status 404
        elsif !current_user
          status 401
        else
          # DEPRECATED: this will be removed by 1st of December
          #
          # TODO It seems this endpoint is still in use, quite a bit:
          # https://metrics.librato.com/s/metrics/api.request.restart?duration=2419200&q=api.request.restart
          #
          # I think we need to properly deprecate this by publishing a blog post.
          Metriks.meter("api.v2.request.restart").mark
          service = Travis::Enqueue::Services::RestartModel.new(current_user, params)
          disallow_migrating!(service.repository)

          params[:user_id] = current_user.id
          type = params[:build_id] ? 'build' : 'job'
          params[:id] = params[:build_id] || params[:job_id]

          Travis.logger.warn "Deprecated endpoint POST /requests: #{params}"

          service.push("#{type}:restart", params)
          respond_with(result: true, flash: service.messages)
        end
      end
    end
  end
end
