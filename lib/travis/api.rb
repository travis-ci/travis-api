module Travis
  module Api
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

    def post(url)
      conn.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end
  end
end

Travis::API = Travis::Api
