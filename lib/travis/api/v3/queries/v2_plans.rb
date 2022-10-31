module Travis::API::V3
  class Queries::V2Plans < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      if params['organization.id']
        client.v2_plans_for_organization(params['organization.id'])
      else
        client.v2_plans_for_user
      end
    end
  end
end
