module Travis::API::V3
  class Services::AccountEnvVar::Delete < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      access_control.permissions(account_env_var).delete!

      query(:account_env_var).delete(params, access_control.user)
      deleted
    end
  end
end
