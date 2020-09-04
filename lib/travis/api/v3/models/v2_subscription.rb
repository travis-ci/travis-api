module Travis::API::V3
  class Models::V2Subscription
    include Models::Owner

    attr_reader :id, :plan, :permissions, :source, :billing_info, :credit_card_info, :owner, :client_secret, :payment_intent, :addons, :created_at

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      plan_data = attributes.fetch('plan_config')
      @plan = plan_data && Models::V2PlanConfig.new(plan_data)
      @permissions = Models::BillingPermissions.new(attributes.fetch('permissions'))
      @source = attributes.fetch('source')
      @billing_info = attributes['billing_info'] && Models::V2BillingInfo.new(@id, attributes['billing_info'])
      @credit_card_info = attributes['credit_card_info'] && Models::V2CreditCardInfo.new(@id, attributes['credit_card_info'])
      @payment_intent = attributes['payment_intent'] && Models::PaymentIntent.new(attributes['payment_intent'])
      @owner = fetch_owner(attributes.fetch('owner'))
      @client_secret = attributes.fetch('client_secret')
      @addons = attributes.fetch('addons')
      @created_at = attributes.fetch('created_at')
    end
  end

  class Models::V2BillingInfo
    attr_reader :id, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code

    def initialize(id, attrs)
      @id = id
      @address = attrs.fetch('address')
      @address2 = attrs.fetch('address2')
      @billing_email = attrs.fetch('billing_email')
      @city = attrs.fetch('city')
      @company = attrs.fetch('company')
      @country = attrs.fetch('country')
      @first_name = attrs.fetch('first_name')
      @last_name = attrs.fetch('last_name')
      @state = attrs.fetch('state')
      @vat_id = attrs.fetch('vat_id')
      @zip_code = attrs.fetch('zip_code')
    end
  end

  class Models::V2CreditCardInfo
    attr_reader :id, :card_owner, :expiration_date, :last_digits

    def initialize(id, attrs)
      @id = id
      @card_owner = attrs.fetch('card_owner')
      @expiration_date = attrs.fetch('expiration_date')
      @last_digits = attrs.fetch('last_digits')
    end
  end
end
