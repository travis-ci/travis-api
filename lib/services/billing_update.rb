
module Services
  class BillingUpdate
    attr_reader :subscription, :subscription_params

    def initialize(subscription, subscription_params)
      @subscription = subscription
      @subscription_params = subscription_params
    end

    def call
      update_address
    end

    def update_address
      address_data = @subscription_params.each{|key,value| value}
      client = Services::BillingClient.new
      client.update_address_request(@subscription, address_data)
    end
  end
end
