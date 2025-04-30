module Travis::API::V3
  class Services::V2Subscription::Share < Service
    params :receiver_id, :receiver
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      if @env['REQUEST_METHOD'] == 'DELETE' then
        query.delete_share(access_control.user.id, params['receiver_id'])
      else
        query.share(access_control.user.id, params['receiver_id'])
      end
      no_content
    end
  end
end
