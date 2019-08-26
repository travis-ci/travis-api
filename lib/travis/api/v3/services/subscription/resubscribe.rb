module Travis::API::V3
  class Services::Subscription::Resubscribe < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query.resubscribe(access_control.user.id), status: 201
    end
  end
end
