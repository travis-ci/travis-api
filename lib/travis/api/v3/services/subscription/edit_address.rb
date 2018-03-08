module Travis::API::V3
  class Services::Subscription::EditAddress < Service
    params :address

    def run!
      current_user_id = access_control.user.id
      query(:subscription).edit_address(current_user_id, params['address'])
    end
  end
end
