module Travis
  module LegacyApi
    def endpoint
      Travis::Config.load.api_endpoint
    end

    def conn
      @conn ||= Faraday.new(url: endpoint) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def delete(url, access_token, body={})
      conn.delete do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{access_token}"
        req.headers['Travis-API-Version'] = '2'
        req.body = body
      end
    end

    def get(url, access_token)
      conn.get do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{access_token}"
        req.headers['Travis-API-Version'] = '2'
      end
    end

    def post(url, access_token)
      conn.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{access_token}"
        req.headers['Travis-API-Version'] = '2'
      end
    end
  end
end

Travis::LegacyAPI = Travis::LegacyApi