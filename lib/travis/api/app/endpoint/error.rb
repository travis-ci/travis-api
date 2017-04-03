require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Error < Endpoint
      set prefix: '/error'

      get '/500' do
        raise 'user-triggered 500'
      end
    end
  end
end
