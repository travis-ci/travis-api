require 'travis/api/app'
require 'useragent'

class Travis::Api::App
  class Middleware
    class RequestId < Middleware
      before do
        if env['HTTP_X_REQUEST_ID']
          headers['X-Request-ID'] = env['HTTP_X_REQUEST_ID']
        end
      end
    end
  end
end
