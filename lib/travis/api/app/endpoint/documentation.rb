require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Documentation < Endpoint
      set prefix: '/docs'

      get '/' do
        redirect "http://docs.travis-ci.com/api"
      end
    end
  end
end
