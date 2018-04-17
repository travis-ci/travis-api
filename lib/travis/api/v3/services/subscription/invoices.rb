module Travis::API::V3
  class Services::Subscription::Invoices < Service
    result_type :invoices

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:invoices).all(access_control.user.id)
    end
  end
end
