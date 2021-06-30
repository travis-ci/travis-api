module Travis::API::V3
  class Services::V2Subscription::ToggleAutoRefill < Service
    params :enabled
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.toggle_auto_refill(access_control.user.id, params['subscription.id'])
      no_content
    end
  end
end
