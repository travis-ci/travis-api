require 'travis/api/app'
require 'travis/api/workers/build_cancellation'
require 'travis/api/workers/build_restart'
require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        prefer_follower do
          name = params[:branches] ? :find_branches : :find_builds
          params['ids'] = params['ids'].split(',') if params['ids'].respond_to?(:split)
          respond_with service(name, params)
        end
      end

      get '/:id' do
        respond_with service(:find_build, params)
      end

      post '/:id/cancel' do
        Metriks.meter("api.request.cancel_build").mark

        if Travis::Features.owner_active?(:enqueue_to_hub, current_user)
          service = Travis::Enqueue::Services::CancelModel.new(current_user, { build_id: params[:id] })
        else
          service = self.service(:cancel_build, params.merge(source: 'api'))
        end

        if !service.authorized?
          json = { error: {
            message: "You don't have access to cancel build(#{params[:id]})"
          } }

          Metriks.meter("api.request.cancel_build.unauthorized").mark
          status 403
          respond_with json
        elsif !service.can_cancel?
          json = { error: {
            message: "The build(#{params[:id]}) can't be canceled",
            code: 'cant_cancel'
          } }

          Metriks.meter("api.request.cancel_build.cant_cancel").mark
          status 422
          respond_with json
        else
          if service.respond_to?(:push)
            service.push
          else
            Travis::Sidekiq::BuildCancellation.perform_async(id: params[:id], user_id: current_user.id, source: 'api')
          end

          Metriks.meter("api.request.cancel_build.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.request.restart_build").mark
        if Travis::Features.owner_active?(:enqueue_to_hub, current_user)
          service = Travis::Enqueue::Services::RestartModel.new(current_user, { build_id: params[:id] })
          if !service.accept?
            status 400
            result = false
          else
            payload = {id: params[:id], user_id: current_user.id}
            service.push("build:restart", payload)
            status 202
            result = true
          end
        else
          service = self.service(:reset_model, build_id: params[:id])
          if !service.accept?
            status 400
            result = false
          else
            Travis::Sidekiq::BuildRestart.perform_async(id: params[:id], user_id: current_user.id)
            status 202
            result = true
          end
        end

        respond_with(result: result, flash: service.messages)
      end
    end
  end
end
