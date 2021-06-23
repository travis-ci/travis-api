module Travis::API::V3
  class Queries::V2Subscription < Query
    params :enabled

    def update_address(user_id)
      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_v2_address(params['subscription.id'], address_data)
    end

    def update_creditcard(user_id)
      client = BillingClient.new(user_id)
      client.update_v2_creditcard(params['subscription.id'], params['token'])
    end

    def changetofree(user_id)
      data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.changetofree_v2_subscription(params['subscription.id'], data)
    end

    def update_plan(user_id)
      plan_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_v2_subscription(params['subscription.id'], plan_data)
    end

    def buy_addon(user_id)
      client = BillingClient.new(user_id)
      client.purchase_addon(params['subscription.id'], params['addon.id'])
    end

    def invoices(user_id)
      client = BillingClient.new(user_id)
      client.get_invoices_for_v2_subscription(params['subscription.id'])
    end

    def pay(user_id)
      client = BillingClient.new(user_id)
      client.pay_v2(params['subscription.id'])
    end

    def get_auto_refill(user_id)
      client = BillingClient.new(user_id)
      puts "sv2.get_auto_refill: #{enabled.inspect}, user: #{user_id}"
      client.get_auto_refill(user_id)
    end

    def toggle_auto_refill(user_id)
      client = BillingClient.new(user_id)
      puts "sv2.create refill parm: #{enabled.inspect}, user: #{user_id}"
      client.create_auto_refill(user_id, enabled)
    end
  end
end
