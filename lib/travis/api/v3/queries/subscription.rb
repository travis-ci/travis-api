module Travis::API::V3
  class Queries::Subscription < RemoteQuery
    params :id

    def find
      #call Billing service
    end

    def for_owner(owner)
      ##call Billing service to get subscription from specific owner
    end
  end
end
