module Travis::API::V3
  class Queries::Coupons < Query
    def find(user_id, code)
      client = BillingClient.new(user_id)
      client.get_coupon(code)
    end
  end
end
