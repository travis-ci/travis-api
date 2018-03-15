module Travis::API::V3
  class Services::Subscription::Cancel < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.cancel(access_control.user.id)
      accepted
    end
  end
end
