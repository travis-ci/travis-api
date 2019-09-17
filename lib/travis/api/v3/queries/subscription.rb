module Travis::API::V3
  class Queries::Subscription < Query
    def update_address(user_id)
      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_address(params['subscription.id'], address_data)
    end

    def cancel(user_id)
      reason_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.cancel_subscription(params['subscription.id'], reason_data)
    end

    def update_creditcard(user_id)
      client = BillingClient.new(user_id)
      client.update_creditcard(params['subscription.id'], params['token'])
    end

    def update_plan(user_id)
      plan_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_plan(params['subscription.id'], plan_data)
    end

    def resubscribe(user_id)
      client = BillingClient.new(user_id)
      client.resubscribe(params['subscription.id'])
    end

    def invoices(user_id)
      client = BillingClient.new(user_id)
      client.get_invoices_for_subscription(params['subscription.id'])
    end

    def trial(user_id)
      client = BillingClient.new(user_id)
      client.get_trial_info_for_subscription(params['subscription.id'])
    end

    def pay(user_id)
      client = BillingClient.new(user_id)
      client.pay(params['subscription.id'])
    end
  end
end
