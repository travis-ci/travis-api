module Travis::API::V3
  class Queries::CreditsCalculator < Query
    params :users, :executions

    def calculate(user_id)
      client = BillingClient.new(user_id)
      client.calculate_credits(params['users'], params['executions'])
    end

    def default_config(user_id)
      client = BillingClient.new(user_id)
      client.credits_calculator_default_config
    end
  end
end
