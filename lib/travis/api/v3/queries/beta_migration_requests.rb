module Travis::API::V3
  class Queries::BetaMigrationRequests < Query

    def find(user)
      Models::BetaMigrationRequest.where(owner_id: user.id)
    end
  end
end
