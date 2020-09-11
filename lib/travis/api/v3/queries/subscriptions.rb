module Travis::API::V3
  class Queries::Subscriptions < Query
    params :plan, :coupon, :organization_id, :client_secret
    params :first_name, :last_name, :company, :address, :address2, :city, :country, :state, :vat_id, :zip_code, :billing_email, :has_local_registration, prefix: :billing_info
    params :token, prefix: :credit_card_info

    def all(user_id)
      client = BillingClient.new(user_id)
      client.all
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      client.create_subscription(
        :plan => params['plan'],
        :client_secret => params['client_secret'],
        :coupon => params['coupon'],
        :organization_id => params['organization_id'],
        :billing_info => billing_info_params,
        :credit_card_info => credit_card_info_params
        )
    end
  end
end
