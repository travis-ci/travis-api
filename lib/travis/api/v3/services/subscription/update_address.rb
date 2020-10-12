module Travis::API::V3
  class Services::Subscription::UpdateAddress < Service
    params :first_name, :last_name, :company, :address, :address2, :city, :country, :state, :vat_id, :zip_code, :billing_email, :has_local_registration

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_address(access_control.user.id)
      no_content
    end
  end
end
