module Travis::API::V3
  class Models::Subscription
    attr_reader :id, :valid_to, :plan, :coupon, :status, :source, :billing_info, :credit_card_info, :owner

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @valid_to = attributes.fetch('valid_to') && DateTime.parse(attributes.fetch('valid_to'))
      @plan = attributes.fetch('plan')
      @coupon = attributes['coupon']
      @status = attributes.fetch('status')
      @source = attributes.fetch('source')
      @billing_info = attributes['billing_info']
      @credit_card_info = attributes['credit_card_info']
      @owner = attributes.fetch('owner')
    end
  end
end
