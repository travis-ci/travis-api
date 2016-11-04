module Travis
  module LegacyApi
    def token
      ENV['TRAVIS_API_TOKEN']
    end

    def endpoint
      ENV['TRAVIS_API_ENDPOINT']
    end

    def conn
      @conn ||= Faraday.new(url: endpoint) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger if !Rails.env.test?
        faraday.adapter  Faraday.default_adapter
      end
    end

    def delete(url, body)
      conn.delete do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{token}"
        req.headers['Travis-API-Version'] = '2'
        req.body = body
      end
    end

    def get(url)
      conn.get do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{token}"
        req.headers['Travis-API-Version'] = '2'
      end

      conn.response :json, :content_type => 'application/json'
    end

    def post(url)
      conn.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{token}"
        req.headers['Travis-API-Version'] = '2'
      end
    end
  end
end

Travis::LegacyAPI = Travis::LegacyApi