module Travis::API::V3
  class Services::V2Subscription::Pay < Service
    result_type :v2_subscription

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query.pay(access_control.user.id), status: 200
    end
  end
end
