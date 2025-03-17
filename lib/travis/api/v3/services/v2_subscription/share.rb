module Travis::API::V3
  class Services::V2Subscription::Share < Service
    params :receiver_id, :receiver
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      puts "PARAMS: #{params.inspect}"
      query.share(access_control.user.id, params['receiver_id'])
      no_content
    end
  end
end
