module Travis::API::V3
  class Services::V2Subscriptions::Create < Service
    result_type :v2_subscription
    params :plan, :coupon, :organization_id, :client_secret, :v1_subscription_id
    params :first_name, :last_name, :company, :address, :address2, :city, :country, :state, :vat_id, :zip_code, :billing_email, :has_local_registration, prefix: :billing_info
    params :token, :fingerprint, prefix: :credit_card_info

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:v2_subscriptions).create(access_control.user.id), status: 201
    end
  end
end
