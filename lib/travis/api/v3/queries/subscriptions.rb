module Travis::API::V3
  class Queries::Subscriptions < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.all
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      client.create_subscription(params)
    end
  end
end
