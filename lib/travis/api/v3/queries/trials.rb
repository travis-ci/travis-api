module Travis::API::V3
  class Queries::Trials < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.trials
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      client.create_trial(params['type'], params['owner'])
      client.trials
    end
  end
end
