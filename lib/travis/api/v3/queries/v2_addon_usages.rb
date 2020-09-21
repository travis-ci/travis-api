module Travis::API::V3
  class Queries::V2AddonUsages < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      if params['subscription.id']
        client.v2_subscription_user_usages(params['subscription.id'])
      end
    end
  end
end
