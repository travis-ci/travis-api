require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Logs < Endpoint
      before { authenticate_by_mode! }

      get '/:id' do |id|
        respond_with service(:find_log, params)
      end
    end
  end
end
