module Travis::API
  # Implements Cross-Origin Resource Sharing. Supported by all major browsers.
  # See http://www.w3.org/TR/cors/
  #
  # TODO: Be smarter about origin.
  class CORS
    GENERAL_HEADERS = {
      'Access-Control-Allow-Origin'      => "*",
      'Access-Control-Allow-Credentials' => "true",
      'Access-Control-Expose-Headers'    => "Content-Type, Cache-Control, Expires, Etag, Last-Modified",
    }

    OPTION_HEADERS = {
      # make sure to update nginx.conf.erb when you update this
      'Access-Control-Allow-Methods' => "HEAD, GET, POST, PATCH, PUT, DELETE",
      'Access-Control-Allow-Headers' => "Content-Type, Authorization, Accept, If-None-Match, If-Modified-Since, X-User-Agent, Travis-API-Version",

      # cache OPTIONS for 24 hours to avoid excessive preflight requests and speed up access
      # browsers might still limit this value to 10 minutes, see caveats
      # http://stackoverflow.com/a/12021982
      'Access-Control-Max-Age' => "86400",
    }

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers &&= GENERAL_HEADERS.merge(headers)
      headers &&= OPTION_HEADERS.merge(headers) if env.fetch('REQUEST_METHOD'.freeze) == 'OPTIONS'.freeze
      [ status, headers, body ]
    end
  end
end
