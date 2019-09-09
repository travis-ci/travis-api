module Travis::API::V3
  class Services::Subscription::Cancel < Service
    params :reason, :reason_details

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.cancel(access_control.user.id)
      no_content
    end
  end
end
