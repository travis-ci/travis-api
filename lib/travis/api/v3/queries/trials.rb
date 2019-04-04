module Travis::API::V3
  class Queries::Trials < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.trials
    end
  end
end
