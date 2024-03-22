module Travis::API::V3
  class Services::V2Subscription::Pause < Service
    params :reason, :reason_details

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.pause(access_control.user.id)
      no_content
    end
  end
end
