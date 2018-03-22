module Travis::API::V3
  class Models::Subscription < Struct.new(:id, :valid_to, :plan, :coupon, :status, :source, :billing_info, :credit_card_info, :owner)
    def initialize(attributes = {})
      super(
        attributes.fetch('id'),
        attributes.fetch('valid_to') && DateTime.parse(attributes.fetch('valid_to')),
        attributes.fetch('plan'),
        attributes['coupon'],
        attributes.fetch('status'),
        attributes.fetch('source'),
        attributes['billing_info'],
        attributes['credit_card_info'],
        attributes.fetch('owner'))
    end
  end
end
