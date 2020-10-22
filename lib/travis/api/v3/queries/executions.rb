module Travis::API::V3
  class Queries::Executions < Query

    def for_owner(owner, user_id, page, per_page, from, to)
      client = BillingClient.new(user_id)
      client.executions(owner_type(owner), owner.id, page, per_page, from, to)
    end

    private

    def owner_type(owner)
      owner.vcs_type =~ /User/ ? 'user' : 'organization'
    end
  end
end
