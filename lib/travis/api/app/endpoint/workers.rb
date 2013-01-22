require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Workers < Endpoint
      get '/' do
        respond_with service(:find_workers, params), type: :workers
      end

      get '/:id' do
        respond_with service(:find_worker, params), type: :worker
      end
    end
  end
end
