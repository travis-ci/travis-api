module Travis::API::V3
  class Services::Subscriptions::Create < Service
    result_type :subscription
    params :plan, :coupon, :organization_id, :client_secret
    params :first_name, :last_name, :company, :address, :address2, :city, :country, :state, :vat_id, :zip_code, :billing_email, :has_local_registration, prefix: :billing_info
    params :token, prefix: :credit_card_info

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:subscriptions).create(access_control.user.id), status: 201
    end
  end
end
