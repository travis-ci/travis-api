module Services
  class CallTravisApi
    def initialize(api_endpoint: ENV['TRAVIS_API_ENDPOINT'],
                   token: ENV['TRAVIS_TOKEN'])
      @api_endpoint = api_endpoint
      @token = token
    end

    def post(url)
      conn = Faraday.new(url: @api_endpoint) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      conn.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{@token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end
  end
end
