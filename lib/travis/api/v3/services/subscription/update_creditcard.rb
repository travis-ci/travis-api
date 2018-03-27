module Travis::API::V3
  class Services::Subscription::UpdateCreditcard < Service
    params :card_owner, :expiration_date, :last_digits

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_creditcard(access_control.user.id)
      accepted
    end
  end
end
