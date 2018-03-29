module Travis::API::V3
  class Queries::GithubInstallation < Query
    def for_owner(owner)
      Models::GithubInstallation.where(owner_type: owner.class.name.demodulize, owner_id: owner.id)
    end
  end
end