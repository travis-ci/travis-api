module Travis::API::V3
  class GdprClient
    class ConfigurationError < StandardError; end

    def initialize(user_id)
      @user_id = user_id
    end

    def export
      handle_errors_and_respond connection.post("/user/#{@user_id}/export")
    end

    def purge
      handle_errors_and_respond connection.delete("/user/#{@user_id}")
    end

    private

    def handle_errors_and_respond(response)
      case response.status
      when 204
        true
      else
        raise Travis::API::V3::ServerError, 'GDPR system error'
      end
    end

    def connection
      @connection ||= Faraday.new(url: gdpr_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
        conn.request(:authorization, 'Token',"token=\"#{gdpr_auth_token}\"")
        conn.headers['X-Travis-User-Id'] = @user_id.to_s
        conn.headers['X-Travis-Source'] = 'travis-api'
        conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        conn.adapter :net_http
      end
    end

    def gdpr_url
      Travis.config.gdpr.endpoint || raise(ConfigurationError, 'No gdpr url configured')
    end

    def gdpr_auth_token
      Travis.config.gdpr.auth_token || raise(ConfigurationError, 'No gdpr auth token configured')
    end
  end
end
