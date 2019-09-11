module Travis::API::V3
  class Queries::Plans < Query
    def all(user_id)
      client = BillingClient.new(user_id)
      if params['organization.id']
        client.plans_for_organization(params['organization.id'])
      else
        client.plans_for_user
      end
    end
  end
end
