module Travis::API::V3
  class RecaptchaClient
    class ConfigurationError < StandardError; end

    def verify(token)
      response = connection.post('/recaptcha/api/siteverify') do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form({ secret: recaptcha_secret, response: token })
      end
      handle_errors_and_respond(response) { |r| r['success'] }
    end

    private

    def handle_errors_and_respond(response)
      case response.status
      when 200, 201
        yield(JSON.parse(response.body)) if block_given?
      when 204
        true
      else
        raise Travis::API::V3::ServerError, 'ReCaptcha system error'
      end
    end

    def connection
      @connection ||= Faraday.new(url: recaptcha_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter Faraday.default_adapter
      end
    end

    def recaptcha_url
      Travis.config.recaptcha.endpoint || raise(ConfigurationError, 'No recaptcha url configured')
    end

    def recaptcha_secret
      Travis.config.recaptcha.secret || raise(ConfigurationError, 'No recaptcha secret configured')
    end
  end
end
