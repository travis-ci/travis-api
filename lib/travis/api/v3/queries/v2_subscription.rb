module Travis::API::V3
  class Queries::V2Subscription < Query
    params :enabled, :threshold, :amount

    def update_payment_details(user_id)
      recaptcha_redis_key = "recaptcha_attempts_v2_#{params['subscription.id']}"
      count = Travis.redis.get(recaptcha_redis_key)&.to_i
      count = count.nil? ? 0 : count
      if count > captcha_max_failed_attempts
        raise ClientError, 'Error verifying reCAPTCHA, you have exausted your attempts, please wait.'
      end

      result = recaptcha_client.verify(params['captcha_token'])
      unless result
        if count == 0
          Travis.redis.setex(recaptcha_redis_key, captcha_block_duration, count + 1)
        else
          ttl = Travis.redis.ttl(recaptcha_redis_key)
          Travis.redis.setex(recaptcha_redis_key, ttl, count + 1)
        end
        raise ClientError, 'Error verifying reCAPTCHA, please try again.'
      end

      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      address_data = address_data.tap { |h| h.delete('token') }
      client = BillingClient.new(user_id)
      client.update_v2_address(params['subscription.id'], address_data) unless address_data.empty?
      client.update_v2_creditcard(params['subscription.id'], params['token'], params['fingerprint']) if params.key?('token')
    end

    def update_address(user_id)
      address_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.update_v2_address(params['subscription.id'], address_data)
    end

    def update_creditcard(user_id)
      client = BillingClient.new(user_id)
      client.update_v2_creditcard(params['subscription.id'], params['token'], params['fingerprint'])
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

    def get_auto_refill(user_id, plan_id)
      client = BillingClient.new(user_id)
      client.get_auto_refill(plan_id)
    end

    def toggle_auto_refill(user_id, plan_id)
      client = BillingClient.new(user_id)
      client.create_auto_refill(plan_id, enabled)
    end

    def cancel(user_id)
      reason_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.cancel_v2_subscription(params['subscription.id'], reason_data)
    end

    def pause(user_id)
      reason_data = params.dup.tap { |h| h.delete('subscription.id') }
      client = BillingClient.new(user_id)
      client.pause_v2_subscription(params['subscription.id'], reason_data)
    end

    def update_auto_refill(user_id, addon_id)
      client = BillingClient.new(user_id)
      client.update_auto_refill(addon_id, threshold, amount)
    end

    private 

    def recaptcha_client
      @recaptcha_client ||= RecaptchaClient.new
    end

    def captcha_block_duration
      Travis.config.antifraud.captcha_block_duration
    end

    def captcha_max_failed_attempts
      Travis.config.antifraud.captcha_max_failed_attempts
    end
  end
end
