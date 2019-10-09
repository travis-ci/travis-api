module Travis::API::V3
  class Models::Coupon
    ATTRS = %w[id name percent_off amount_off valid]

    attr_accessor *ATTRS

    def initialize(attrs)
      ATTRS.each { |key| send("#{key}=", attrs[key]) }
    end
  end
end
