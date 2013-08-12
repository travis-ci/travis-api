require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Builds < Endpoint
      get '/' do
        name = params[:branches] ? :find_branches : :find_builds
        params['ids'] = params['ids'].split(',') if params['ids'].respond_to?(:split)
        respond_with service(name, params)
      end

      get '/:id' do
        respond_with service(:find_build, params)
      end

      post '/:id/cancel' do
        service = self.service(:cancel_build, params)
        if !service.authorized?
          json = { error: {
            message: "You don't have access to cancel build(#{params[:id]})"
          } }
          status 403
          respond_with json
        elsif !service.can_cancel?
          json = { error: {
            message: "The build(#{params[:id]}) can't be canceled",
            code: 'cant_cancel'
          } }
          status 422
          respond_with json
        else
          service.run
          status 204
        end
      end
    end
  end
end
