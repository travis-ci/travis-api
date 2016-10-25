module Travis
  module Api
    def token
      if Rails.env.development?
        ENV['TRAVIS_API_TOKEN']
      else
        Travis::AccessToken.create(user: user, app_id: 2) if user
      end
    end

    def endpoint
      Travis::Config.load.api_endpoint
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
