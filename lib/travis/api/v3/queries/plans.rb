module Travis::API::V3
  class Queries::Plans < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.plans(params['organization_id'], params['subscription_id'])
    end
  end
end
