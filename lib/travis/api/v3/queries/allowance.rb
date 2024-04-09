module Travis::API::V3
  class Queries::Allowance < Query
    params :login, :github_id, :provider

    def for_owner(owner, user_id)
      return true if !!Travis.config.enterprise

      client = BillingClient.new(user_id)
      client.allowance(owner_type(owner), owner.id)
    end

    private

    def owner_type(owner)
      owner.vcs_type =~ /User/ ? 'user' : 'organization'
    end
  end
end
