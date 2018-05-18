module Travis::API::V3
  class Models::Subscription
    attr_reader :id, :valid_to, :plan, :coupon, :status, :source, :billing_info, :credit_card_info, :owner

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @valid_to = attributes.fetch('valid_to') && DateTime.parse(attributes.fetch('valid_to'))
      plan_data = attributes.fetch('plan')
      @plan = plan_data && Models::Plan.new(plan_data)
      @coupon = attributes['coupon']
      @status = attributes.fetch('status')
      @source = attributes.fetch('source')
      @billing_info = attributes['billing_info'] && Models::BillingInfo.new(@id, attributes['billing_info'])
      @credit_card_info = attributes['credit_card_info'] && Models::CreditCardInfo.new(@id, attributes['credit_card_info'])
      @owner = fetch_owner(attributes.fetch('owner'))
    end

    private

    def fetch_owner(attributes)
      owner_class = case attributes.fetch('type')
                    when 'User'
                      Models::User
                    when 'Organization'
                      Models::Organization
                    end
      owner_class.find(attributes.fetch('id'))
    end
  end

  class Models::BillingInfo
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

  class Models::CreditCardInfo
    attr_reader :id, :card_owner, :expiration_date, :last_digits

    def initialize(id, attrs)
      @id = id
      @card_owner = attrs.fetch('card_owner')
      @expiration_date = attrs.fetch('expiration_date')
      @last_digits = attrs.fetch('last_digits')
    end
  end
end
