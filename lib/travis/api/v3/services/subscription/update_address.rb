module Travis::API::V3
  class Services::Subscription::UpdateAddress < Service
    params :address

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_address(access_control.user.id)
      accepted
    end
  end
end
