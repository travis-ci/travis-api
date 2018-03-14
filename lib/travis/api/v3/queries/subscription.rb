module Travis::API::V3
  class Queries::Subscription < Query
    def update_address(user_id)
      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = Billing.new(user_id)
      client.update_address(params['subscription.id'], address_data)
    end
  end
end
