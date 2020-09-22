module Travis::API::V3
  class Services::V2Subscription::UserUsages < Service
    params :subscription_id
    result_type :v2_addon_usages

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:v2_addon_usages).all(access_control.user.id)
    end
  end
end
