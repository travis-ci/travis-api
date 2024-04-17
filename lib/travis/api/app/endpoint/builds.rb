require 'travis/api/app'
require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      before { authenticate_by_mode! }

      get '/' do
        prefer_follower do
          name = params[:branches] ? :find_branches : :find_builds
          params['ids'] = params['ids'].split(',') if params['ids'].respond_to?(:split)
          respond_with service(name, params), include_log_id: include_log_id?
        end
      end

      get '/:id' do
        respond_with service(:find_build, params), type: :build, include_log_id: include_log_id?
      end

      post '/:id/cancel' do
        Metriks.meter("api.v2.request.cancel_build").mark


        service = Travis::Enqueue::Services::CancelModel.new(current_user, { build_id: params[:id] })
        auth_for_repo(service&.target&.repository&.id, 'repository_build_cancel') unless Travis.config.legacy_roles

        if !service.authorized?
          json = { error: {
            message: "You don't have access to cancel build(#{params[:id]})"
          } }

          Metriks.meter("api.v2.request.cancel_build.unauthorized").mark
          status 403
          respond_with json
        elsif !service.can_cancel?
          json = { error: {
            message: "The build(#{params[:id]}) can't be canceled",
            code: 'cant_cancel'
          } }

          Metriks.meter("api.v2.request.cancel_build.cant_cancel").mark
          status 422
          respond_with json
        else
          payload = { id: params[:id], user_id: current_user.id, source: 'api', reason: "Build Cancelled manually by User: #{current_user.login}" }

          service.push("build:cancel", payload)

          Metriks.meter("api.v2.request.cancel_build.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.v2.request.restart_build").mark


        service = Travis::Enqueue::Services::RestartModel.new(current_user, build_id: params[:id])
        disallow_migrating!(service.repository)

        auth_for_repo(service.repository.id, 'repository_build_restart') unless Travis.config.legacy_roles

        result = if !service.accept?
          status 400
          false
        else
          payload = { id: params[:id], user_id: current_user.id, restarted_by: current_user.id }
          service.push("build:restart", payload)
          status 202
          true
        end

        respond_with(result: result, flash: service.messages)
      end
    end

    private def include_log_id?
      params[:include_log_id] ||
        request.user_agent.to_s.start_with?('Travis')
    end
  end
end
