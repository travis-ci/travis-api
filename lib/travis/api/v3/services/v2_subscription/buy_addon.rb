module Travis::API::V3
  class Services::V2Subscription::BuyAddon < Service
    params :plan

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.buy_addon(access_control.user.id)
      no_content
    end
  end
end
