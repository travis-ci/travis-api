module Services
  class CallTravisApi
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def post
      conn = Faraday.new(:url => 'https://api-staging.travis-ci.com') do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      conn.post do |req|
        req.url @url
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "token #{ENV['TRAVIS_TOKEN']}"
        req.headers['Travis-API-Version'] = '3'
      end
    end
  end
end
