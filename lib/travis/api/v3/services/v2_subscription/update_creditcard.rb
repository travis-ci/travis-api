module Travis::API::V3
  class Services::V2Subscription::UpdateCreditcard < Service
    params :token, :fingerprint

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_creditcard(access_control.user.id)
      no_content
    end
  end
end
