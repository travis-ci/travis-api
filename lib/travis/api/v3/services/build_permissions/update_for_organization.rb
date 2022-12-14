module Travis::API::V3
  class Services::BuildPermissions::UpdateForOrganization < Service
    params :user_ids, :permission

    def run!
      organization = check_login_and_find(:organization)

      raise LoginRequired unless access_control.adminable?(organization)
      raise ClientError, 'user_ids must be an array' unless params['user_ids'].is_a?(Array)
      query.update_for_organization(organization, params['user_ids'], params['permission'])

      no_content
    end
  end
end
