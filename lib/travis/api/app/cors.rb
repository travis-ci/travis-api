require 'travis/api/app'

class Travis::Api::App
  # Implements Cross-Origin Resource Sharing. Supported by all major browsers.
  # See http://www.w3.org/TR/cors/
  #
  # TODO: Be smarter about origin.
  class Cors < Base
    before do
      headers['Access-Control-Allow-Origin']      = "*"
      headers['Access-Control-Allow-Credentials'] = "true"
      headers['Access-Control-Expose-Headers']    = "Content-Type, Cache-Control, Expires, Etag, Last-Modified"
    end

    options // do
      headers['Access-Control-Allow-Methods'] = "HEAD, GET, POST, PATCH, PUT, DELETE"
      headers['Access-Control-Allow-Headers'] = "Content-Type, Authorization, Accept, If-None-Match, If-Modified-Since, X-User-Agent, Travis-API-Version"

      # cache OPTIONS for 24 hours to avoid excessive preflight requests and speed up access
      # browsers might still limit this value to 10 minutes, see caveats
      # http://stackoverflow.com/a/12021982
      headers['Access-Control-Max-Age'] = "86400"
    end
  end
end
