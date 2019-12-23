require 'faraday'

module Travis::API::V3::Models
  class RepositoryMigration
    class MigrationDisabledError < StandardError; end
    class MigrationRequestFailed < StandardError; end
    attr_accessor :repository

    def initialize(repository)
      self.repository = repository
    end

    def migrate!
      raise MigrationDisabledError unless repository.allow_migration?

      token = Travis.config.merge.auth_token
      url   = Travis.config.merge.api_url
      connection = Faraday.new(url: url) do |c|
        c.request :json
        c.headers['Content-Type'] = 'application/json'
        c.use Faraday::Request::Authorization, 'Token', token
        c.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
        c.adapter Faraday.default_adapter
      end
      response = connection.post("/api/repo/by_github_id/#{repository.vcs_id || repository.github_id}/migrate")

      unless response.success?
        raise MigrationRequestFailed
      end
    end
  end
end
