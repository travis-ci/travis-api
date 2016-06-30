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

        service = Travis::Enqueue::Services::CancelModel.new(current_user, { build_id: params[:id] })

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
          payload = { id: params[:id], user_id: current_user.id, source: 'api' }

          service.push("build:cancel", payload)

          Metriks.meter("api.request.cancel_build.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.request.restart_build").mark
        service = Travis::Enqueue::Services::RestartModel.new(current_user, build_id: params[:id])

        result = if !service.accept?
          status 400
          false
        else
          payload = { id: params[:id], user_id: current_user.id }
          service.push("build:restart", payload)
          status 202
          true
        end

        respond_with(result: result, flash: service.messages)
      end
    end
  end
end
