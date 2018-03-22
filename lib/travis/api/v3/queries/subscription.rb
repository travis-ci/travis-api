module Travis::API::V3
  class Queries::Subscription < Query
    def update_address(user_id)
      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_address(params['subscription.id'], address_data)
    end

    def cancel(user_id)
      client = BillingClient.new(user_id)
      client.cancel_subscription(params['subscription.id'])
    end

    def update_creditcard(user_id)
      creditcard_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_creditcard(params['subscription.id'], creditcard_data)
    end
  end
end
