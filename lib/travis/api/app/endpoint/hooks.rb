require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Hooks < Endpoint
      get '/', scope: :private do
        respond_with service(:find_hooks, params), type: :hooks
      end

      put '/:id?', scope: :private do
        respond_with service(:update_hook, id: params[:id] || params[:hook][:id], active: params[:hook][:active])
      end
    end
  end
end
