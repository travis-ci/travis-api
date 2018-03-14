module Travis::API::V3
  class Queries::Subscriptions < Query
    def all(user_id)
      client = Billing.new(user_id)
      client.all
    end
  end
end
