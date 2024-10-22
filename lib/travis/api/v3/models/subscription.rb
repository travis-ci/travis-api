module Travis::API::V3
  class Models::Subscription
    include Models::Owner

    attr_reader :id, :permissions, :valid_to, :plan, :coupon, :discount, :status, :source, :billing_info, :credit_card_info, :owner, :client_secret, :payment_intent, :created_at,
                :cancellation_requested

    def initialize(attributes = {})
      @id = attributes.fetch('id').to_i
      @permissions = Models::BillingPermissions.new(attributes.fetch('permissions'))
      @valid_to = attributes.fetch('valid_to') && DateTime.parse(attributes.fetch('valid_to'))
      plan_data = attributes.fetch('plan')
      @plan = plan_data && Models::Plan.new(plan_data)
      @coupon = attributes['coupon']
      @status = attributes.fetch('status')
      @source = attributes.fetch('source')
      @billing_info = attributes['billing_info'] && Models::BillingInfo.new(@id, attributes['billing_info'])
      @credit_card_info = attributes['credit_card_info'] && Models::CreditCardInfo.new(@id, attributes['credit_card_info'])
      @payment_intent = attributes['payment_intent'] && Models::PaymentIntent.new(attributes['payment_intent'])
      @discount = attributes['discount'] && Models::Discount.new(attributes['discount'])
      @owner = fetch_owner(attributes.fetch('owner'))
      @client_secret = attributes.fetch('client_secret')
      @created_at = attributes.fetch('created_at')
      @cancellation_requested = attributes.fetch('cancellation_requested')
      @on_trial_period = attributes.fetch('on_trial_period', false)
      current_trial = attributes.fetch('current_trial', nil)
      @current_trial = current_trial && Models::V2Trial.new(current_trial)
    end
  end

  class Models::SubscriptionsCollection
    attr_reader :subscriptions, :permissions

    def initialize(subscriptions, permissions)
      @subscriptions = subscriptions
      @permissions = permissions
    end
  end

  class Models::BillingInfo
    attr_reader :id, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code, :has_local_registration

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
      @has_local_registration= attrs.fetch('has_local_registration')
    end
  end

  class Models::CreditCardInfo
    attr_reader :id, :card_owner, :expiration_date, :last_digits

    def initialize(id, attrs)
      @id = id
      @card_owner = attrs.fetch('card_owner')
      @expiration_date = attrs.fetch('expiration_date')
      @last_digits = attrs.fetch('last_digits')
    end
  end

  class Models::PaymentIntent
    attr_reader :status, :client_secret, :last_payment_error

    def initialize(attrs)
      @status = attrs.fetch('status')
      @client_secret = attrs.fetch('client_secret')
      @last_payment_error = attrs['last_payment_error']
    end
  end

  class Models::Discount
    attr_reader :id, :name, :percent_off, :amount_off, :valid, :duration, :duration_in_months

    def initialize(attrs)
      @id = attrs.fetch('id')
      @name = attrs.fetch('name')
      @percent_off = attrs.fetch('percent_off')
      @amount_off = attrs.fetch('amount_off')
      @valid = attrs.fetch('valid')
      @duration = attrs.fetch('duration')
      @duration_in_months = attrs.fetch('duration_in_months')
    end
  end
end
