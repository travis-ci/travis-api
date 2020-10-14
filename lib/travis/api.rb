module Travis
  module Api
    def conn
      @conn ||= Faraday.new(http_options) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger if !Rails.env.test?
        faraday.adapter  Faraday.default_adapter
      end
    end

    def http_options
      if Travis::Config.load.ssl&.has_key?(:verify) && Travis::Config.load.ssl&.verify == false
        {url: endpoint, ssl: Travis::Config.load.ssl.to_h.merge(verify: false)}.compact
      else
        {url: endpoint}.compact
      end
    end

    def endpoint
      url = URI.parse(Travis::Config.load.api_endpoint)
      "#{url.scheme}://#{url.host}"
    end

    def url_path(url)
      url = URI.parse("#{Travis::Config.load.api_endpoint}#{url}")
      url.path
    end

    def get(url, access_token)
      conn.get do |req|
        req.url url_path(url)
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "token #{access_token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end

    def post(url, access_token)
      conn.post do |req|
        req.url url_path(url)
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "token #{access_token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end

    def post_internal(url, api_token)
      conn.post do |req|
        req.url url_path(url)
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "internal admin:#{api_token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end

    def patch(url, access_token, body={})
      conn.patch do |req|
        req.url url_path(url)
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "token #{access_token}"
        req.headers['Travis-API-Version'] = '3'
        req.body                          = body
      end
    end

    def delete(url, access_token)
      conn.delete do |req|
        req.url url_path(url)
        req.headers['Content-Type']       = 'application/json'
        req.headers['Authorization']      = "token #{access_token}"
        req.headers['Travis-API-Version'] = '3'
      end
    end
  end
end

Travis::API = Travis::Api
