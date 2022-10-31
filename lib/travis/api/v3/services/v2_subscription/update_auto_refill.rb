module Travis::API::V3
  class Services::V2Subscription::UpdateAutoRefill < Service
    params :addon_id, :threshold, :amount
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_auto_refill(access_control.user.id, params['addon_id'])
      no_content
    end
  end
end
