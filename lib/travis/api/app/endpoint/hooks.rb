require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Hooks < Endpoint
      get '/', scope: :private do
        respond_with service(:hooks, :find_all, params), type: :hooks
      end

      put '/:id?', scope: :private do
        respond_with service(:hooks, :update, id: params[:id] || params[:hook][:id], active: params[:hook][:active])
      end
    end
  end
end
