module Travis::API::V3
  class ComApiClient
    class ComApiRequestFailed < StandardError; end

    def create_beta_migration_request(user, organizations)
      response = process_response(connection.post('/v3/beta_migration_requests', {
        user_login: user.login,
        organizations: organizations.map(&:login)
      }))

      map_beta_request(response)
    end

    def find_beta_migration_requests(user)
      response = process_response(connection.get("/v3/beta_migration_requests", user_login: user.login))

      beta_requests = response['beta_migration_requests'] || []

      beta_requests.map(&method(:map_beta_request))
    end

    private

    def process_response(response)
      unless response.success?
        raise ComApiRequestFailed.new(status: response.status, response: response.body)
      end

      JSON.parse(response.body)
    end

    def map_beta_request(response)
      fields = response.slice(*%w(id owner_id owner_name owner_type accepted_at))

      beta_req = Models::BetaMigrationRequest.new(fields)
      beta_req.organizations = Models::Organization.where(login: response['organizations_logins'])

      beta_req
    end

    def connection
      url   = Travis.config.api_com_url
      token = Travis.config.applications[:api_org][:token]

      @connection ||= Faraday.new(url: url) do |c|
        c.request :json
        c.use Faraday::Request::Authorization, 'internal', "api_org:#{token}"
        c.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        c.adapter Faraday.default_adapter
      end
    end
  end
end
