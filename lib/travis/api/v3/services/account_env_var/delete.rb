module Travis::API::V3
  class Services::AccountEnvVar::Delete < Service
    params :id

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      account_env_var = Travis::API::V3::Models::AccountEnvVar.find_by(
        id: params['id']
      )

      if account_env_var
        access_control.permissions(account_env_var).delete!
        query(:account_env_var).delete(account_env_var)
        deleted
      else
        raise NotFound, "No matching environment variable found."
      end
    end
  end
end
