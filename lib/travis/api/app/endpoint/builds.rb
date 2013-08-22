require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        name = params[:branches] ? :find_branches : :find_builds
        params['ids'] = params['ids'].split(',') if params['ids'].respond_to?(:split)

        if params['ids'].empty?
          respond_with({})
        else
          respond_with service(name, params)
        end
      end

      post '/:id/cancel' do
        Metriks.meter("api.request.cancel_build").mark

        service = self.service(:cancel_build, params)
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
    end
  end
end
