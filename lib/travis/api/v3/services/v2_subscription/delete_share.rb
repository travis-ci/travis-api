module Travis::API::V3
  class Services::V2Subscription::DeleteShare < Service
    params  :receiver_id
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.delete_share(access_control.user.id, params['receiver_id'])
      no_content
    end
  end
end
