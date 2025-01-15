module Travis::API::V3
  class Services::AccountEnvVars::Create < Service
    params :owner_id, :owner_type, :name, :value, :public
    result_type :account_env_var

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      result query(:account_env_var).create(params, access_control.user)
    end
  end
end
