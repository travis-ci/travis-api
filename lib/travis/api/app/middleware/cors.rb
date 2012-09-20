require 'travis/api/app'

class Travis::Api::App
  class Middleware
    # Implements Cross-Origin Resource Sharing. Supported by all major browsers.
    # See http://www.w3.org/TR/cors/
    #
    # TODO: Be smarter about origin.
    class Cors < Middleware
      before do
        headers['Access-Control-Allow-Origin']      = "*"
        headers['Access-Control-Allow-Credentials'] = "true"
        headers['Access-Control-Expose-Headers']    = "Content-Type"
      end

      options // do
        headers['Access-Control-Allow-Methods'] = "HEAD, GET, POST, PATCH, PUT, DELETE"
        headers['Access-Control-Allow-Headers'] = "Content-Type, Authorization, Accept"
      end
    end
  end
end
