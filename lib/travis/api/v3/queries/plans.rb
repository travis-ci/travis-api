module Travis::API::V3
  class Queries::Plans < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.plans_for(params['owner.id'])
    end
  end
end
