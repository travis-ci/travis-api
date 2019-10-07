module Travis::API::V3
  class Queries::BetaMigrationRequest < Query
    class ComApiRequestFailed < StandardError; end

    def create(current_user, organizations)
      Travis::API::V3::Models::BetaMigrationRequest.create({
        owner_type:    current_user.class.name.demodulize,
        owner_id:      current_user.id,
        owner_name:    current_user.login,
        organizations: organizations,
        accepted_at: DateTime.now
      })
    end

    def send_create_request(current_user, organizations)
      ComApiClient.new.create_beta_migration_request(current_user, organizations)
    end
  end
end
