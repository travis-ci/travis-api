module Travis::API::V3
  class Queries::V2Invoices < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.get_invoices_for_v2_subscription(params['subscription.id'])
    end
  end
end
