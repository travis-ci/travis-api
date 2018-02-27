module Travis::API::V3
  class Services::Subscription::Cancel < Service

    def run!
      current_user_id = access_control.user.id
      query(:subscription).cancel(current_user_id)
      accepted(payload: params)
    end
  end
end
