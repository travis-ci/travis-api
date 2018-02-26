module Travis::API::V3
  class Services::Subscription::Create < Service
    params :subscription

    def run!
      current_user_id = access_control.user.id
      query(:subscription).create(current_user_id, params['subscription'])
    end
  end
end
