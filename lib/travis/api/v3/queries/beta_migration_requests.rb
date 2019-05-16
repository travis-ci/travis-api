module Travis::API::V3
  class Queries::BetaMigrationRequests < Query

    def find(user)
      return fetch_from_com_api(user) if Travis.config.org?

      Models::BetaMigrationRequest.where(owner_id: user.id)
    end

    def fetch_from_com_api(user)
      ComApiClient.new.find_beta_migration_requests(user)
    end
  end
end
