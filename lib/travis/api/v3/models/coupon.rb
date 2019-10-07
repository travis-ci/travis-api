module Travis::API::V3
  class Models::Coupon
    ATTRS = %i[id name percent_off amount_off value]

    attr_accessor *ATTRS

    def initialize(attrs)
      ATTRS.each { |key| send("#{key}=", attrs[key]) }
    end
  end
end
