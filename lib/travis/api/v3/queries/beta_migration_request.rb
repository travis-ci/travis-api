module Travis::API::V3
  class Queries::BetaMigrationRequest < Query
    class BetaRequestFailed < StandardError; end

    def create(current_user, organizations)
      Travis::API::V3::Models::BetaMigrationRequest.create({
        owner_type:    current_user.class.name.demodulize,
        owner_id:      current_user.id,
        owner_name:    current_user.login,
        organizations: organizations
      })
    end

    def send_create_request(current_user, organizations)
      url   = Travis.config.api_com_url
      token = Travis.config.applications[:api_org][:token]

      connection = Faraday.new(url: url) do |c|
        c.request :json
        c.use Faraday::Request::Authorization, 'internal', "api_org:#{token}"
        c.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        c.adapter Faraday.default_adapter
      end

      response = connection.post('/v3/beta_migration_requests', {
        user_login: current_user.login,
        organizations: organizations.map(&:login)
      })

      unless response.success?
        raise BetaRequestFailed
      end

      body = JSON.parse(response&.body)

      Models::BetaMigrationRequest.new(body.slice(*%w(id owner_id owner_name owner_type accepted_at)))
    end
  end
end
