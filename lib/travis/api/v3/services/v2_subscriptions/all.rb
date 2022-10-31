module Travis::API::V3
  class Services::V2Subscriptions::All < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:v2_subscriptions).all(access_control.user.id)
    end
  end
end
