module Travis::API::V3
  class Queries::Subscriptions < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.all
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      client.create_subscription(
        :plan => params['plan'],
        :coupon => params['coupon'],
        :organization_id => params['organization_id'],
        :billing_info => {
          :first_name => params['billing_info.first_name'],
          :last_name => params['billing_info.last_name'],
          :company => params['billing_info.company'],
          :address => params['billing_info.address'],
          :address2 => params['billing_info.address2'],
          :city => params['billing_info.city'],
          :country => params['billing_info.country'],
          :state => params['billing_info.state'],
          :vat_id => params['billing_info.vat_id'],
          :zip_code => params['billing_info.zip_code'],
          :billing_email => params['billing_info.billing_email']
        },
        :credit_card_info => {
          :card_owner => params['credit_card_info.card_owner'],
          :expiration_date => params['credit_card_info.expiration_date'],
          :last_digits => params['credit_card_info.last_digits']
        }
      )
    end
  end
end
