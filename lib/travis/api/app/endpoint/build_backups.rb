require 'travis/api/app'
require 'travis/api/app/responders/base'

class Travis::Api::App
  class Endpoint
    class BuildBackups < Endpoint
      include Helpers::Accept

      before { authenticate_by_mode! }

      get '/' do
        prefer_follower do
          respond_with service(:find_build_backups, params)
        end
      end
    end
  end
end
