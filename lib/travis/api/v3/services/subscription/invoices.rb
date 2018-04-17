module Travis::API::V3
  class Services::Subscription::Invoices < Service
    type :invoices
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query.invoices(access_control.user.id)
    end
  end
end