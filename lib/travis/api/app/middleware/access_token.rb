require 'travis/api/app'

class Travis::Api::App
  class Middleware
    # Checks access tokens and sets appropriate scopes.
    class AccessToken < Middleware
    end
  end
end
