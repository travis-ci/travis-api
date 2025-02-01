module Travis::API::V3
  class Services::AccountEnvVar::Delete < Service
    params :id

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      account_env_var = Travis::API::V3::Models::AccountEnvVar.find_by(
        id: params['id']
      )

      if account_env_var
        Travis.logger.info "starting deletion"
        access_control.permissions(account_env_var).delete!
        query(:account_env_var).delete(params, access_control.user)
        deleted
      else
        raise NotFound, "No matching environment variable found."
      end
    end
  end
end
