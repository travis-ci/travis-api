module Travis::API::V3
  class Services::Subscriptions::All < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:subscriptions).all(access_control.user.id)
    end
  end
end
