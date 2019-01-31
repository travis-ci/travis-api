module Travis::API::V3
  class Queries::BetaMigrationRequest < Query

    def create(current_user, organizations)
      Travis::API::V3::Models::BetaMigrationRequest.create({
          owner_type:    current_user.class.name.demodulize,
          owner_id:      current_user.id,
          owner_name:    current_user.login,
          organizations: organizations
        })
    end
  end
end
