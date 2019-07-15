module Travis::API::V3
  class Queries::BetaMigrationRequests < Query

    def find(user)
      Models::BetaMigrationRequest.where(owner_id: user.id)
    end

    def fetch_from_api(user)
      ComApiClient.new.find_beta_migration_requests(user)
    end
  end
end
