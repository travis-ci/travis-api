module Travis::API::V3
  class Queries::Subscription < RemoteQuery
    params :id

    def find
      return Models::Subscription.find_by_id(id) if id
    end

    def for_owner(owner)
      owner.subscription
    end
  end
end
