module Travis::API::V3
  class Services::V2Subscription::AutoRefill < Service
    result_type :auto_refill

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query.get_auto_refill(access_control.user.id, params['subscription.id']), status: 200
    end
  end
end
