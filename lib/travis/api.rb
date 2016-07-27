module Travis
  module Api
    def conn
      @conn ||= Faraday.new(url: endpoint) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger if !Rails.env.test?
        faraday.adapter  Faraday.default_adapter
      end
    end

    def endpoint
      Travis::Config.load.api_endpoint
    end

    def post(url, access_token)
      conn.post do |req|
        req.url url
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "token #{access_token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end

    def patch(url, type, body = {})
      conn.patch do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{token}"
        req.headers['Travis-API-Version'] = '3'
        req.body = JSON.dump({"@type": type}.merge(body))
      end
    end
  end
end

Travis::API = Travis::Api
