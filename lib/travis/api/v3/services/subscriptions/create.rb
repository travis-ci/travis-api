module Travis::API::V3
  class Services::Subscriptions::Create < Service
    result_type :subscription
    # TODO: required attributes
    params :street

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:subscriptions).create(access_control.user.id)
    end
  end
end
