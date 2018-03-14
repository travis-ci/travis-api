module Travis::API::V3
  class Services::Subscription::UpdateCreditcard < Service
    params :creditcard_number

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_creditcard(access_control.user.id)
      accepted
    end
  end
end
