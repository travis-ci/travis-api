module Travis::API::V3
  class Services::BuildPermissions::UpdateForRepo < Service
    params :user_ids, :permission

    def run!
      repository = check_login_and_find(:repository)

      raise LoginRequired unless access_control.admin_for(repository)
      raise ClientError, 'user_ids must be an array' unless params['user_ids'].is_a?(Array)
      query.update_for_repo(repository, params['user_ids'], params['permission'])

      no_content
    end
  end
end
