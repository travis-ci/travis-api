module Travis::API::V3
  class Services::V2Subscription::Changetofree < Service
    params :plan

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.changetofree(access_control.user.id)
      no_content
    end
  end
end
