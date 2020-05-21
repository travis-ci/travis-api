module Travis::API::V3
  class Services::Organization::UpdateBillingPermission < Service
    params :billing_admin_only

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_billing_permission(access_control.user.id)
      no_content
    end
  end
end