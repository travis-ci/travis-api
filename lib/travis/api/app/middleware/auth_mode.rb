require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class AuthMode < Middleware
      # halt unauthorized requests unless in public mode or access_token given
      # this needs to happen after the V3::OptIn, so it cannot go into the
      # ScopeCheck middleware
      before do
        return if env['travis.access_token']
        if Travis.config[:public_mode] == false
          halt 401, 'no access token supplied'
        end
      end
    end
  end
end
