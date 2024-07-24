require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Hooks < Endpoint
      before { authenticate_by_mode! }

      get '/', scope: :private do
        respond_with service(:find_hooks, params), type: :hooks
      end

      put '/:id?', scope: :private do
        service = service(:update_hook, id: params[:id] || params[:hook][:id], active: params[:hook][:active])
        auth_for_repo(params[:id] || params[:hook][:id], 'repository_state_update') unless Travis.config.legacy_roles
        disallow_migrating!(service.repo)
        respond_with service
      end
    end
  end
end
