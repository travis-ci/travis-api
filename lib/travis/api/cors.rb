require 'sinatra/base'

module Travis
  module API
    class CORS < Sinatra::Base
      disable :protection

      before do
        headers['Access-Control-Allow-Origin']      = "*"
        headers['Access-Control-Allow-Credentials'] = "true"
        headers['Access-Control-Expose-Headers']    = "Content-Type"
      end

      options // do
        headers['Access-Control-Allow-Methods'] = "GET, POST, PATCH, PUT, DELETE"
        headers['Access-Control-Allow-Headers'] = "Content-Type, Authorization"
      end
    end
  end
end
