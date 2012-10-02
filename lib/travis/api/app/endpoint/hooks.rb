require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Hooks < Endpoint
      get '/', scope: :private do
        body all(params).run, type: :hooks
      end

      put '/:id?', scope: :private do
        update(id: params[:id] || params[:hook][:id], active: params[:hook][:active]).run
        204
      end
    end
  end
end
