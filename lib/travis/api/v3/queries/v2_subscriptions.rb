module Travis::API::V3
  class Queries::V2Subscriptions < Query
    params :plan, :coupon, :organization_id, :client_secret, :v1_subscription_id
    params :first_name, :last_name, :company, :address, :address2, :city, :country, :state, :vat_id, :zip_code, :billing_email, :has_local_registration, prefix: :billing_info
    params :token, :fingerprint, prefix: :credit_card_info

    def all(user_id)
      client = BillingClient.new(user_id)
      client.all_v2
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      client.create_v2_subscription(
        :plan => params['plan'],
        :client_secret => params['client_secret'],
        :coupon => params['coupon'],
        :organization_id => params['organization_id'],
        :billing_info => billing_info_params,
        :credit_card_info => credit_card_info_params,
        :v1_subscription_id => params['v1_subscription_id']
      )
    end
  end
end
