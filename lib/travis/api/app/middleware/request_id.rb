require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class RequestId < Middleware
      before do
        Travis::Honeycomb.context.add('x_request_id', env['HTTP_X_REQUEST_ID'])
      end

      after do
        if env['HTTP_X_REQUEST_ID']
          headers['X-Request-ID'] = env['HTTP_X_REQUEST_ID']
        end
      end
    end
  end
end
