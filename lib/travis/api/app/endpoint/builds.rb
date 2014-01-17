require 'travis/api/app'

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

        service = self.service(:cancel_build, params.merge(source: 'api'))
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
          service.run

          Metriks.meter("api.request.cancel_build.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.request.restart_build").mark
        respond_with service(:reset_model, build_id: params[:id])
      end
    end
  end
end
