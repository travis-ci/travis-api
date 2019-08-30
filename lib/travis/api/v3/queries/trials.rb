module Travis::API::V3
  class Queries::Trials < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      client.trials
    end

    def create(user_id)
      client = BillingClient.new(user_id)
      login = client.create_trial(params['type'], params['owner'])
      client.trials.select { |trial| 
        trial.owner.id.to_s == params['owner'] && 
        trial.owner.class.to_s.split('::').last.downcase == params['type'] &&
        trial.owner.login == login
      }
    end
  end
end
