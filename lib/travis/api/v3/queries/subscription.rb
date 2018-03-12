module Travis::API::V3
  class Queries::Subscription < RemoteQuery
    params :id
    params :current_user_id, :id


    def find
      #call Billing service
    end

    def for_owner(owner)
      ##call Billing service to get subscription from specific owner
    end

    def create(current_user_id, subscription)
      Billing.new(current_user_id).create_subscription(subscription)
    end

    def cancel(current_user_id)
      Billing.new(current_user_id, id).cancel_subscription
    end

    def edit_address(current_user_id, address_params)
      Billing.new(current_user_id, id).edit_address(address_params)
    end
  end
end
