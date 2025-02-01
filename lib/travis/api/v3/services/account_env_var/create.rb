module Travis::API::V3
  class Services::AccountEnvVar::Create < Service
    params :owner_id, :owner_type, :name, :value, :public
    result_type :account_env_var

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      account_env_var = Travis::API::V3::Models::AccountEnvVar.new(
        owner_type: params['owner_type'],
        owner_id: params['owner_id'],
        name: params['name'],
        value: params['value'],
        public: params['public']
      )

      access_control.permissions(account_env_var).write?

      result query(:account_env_var).create(params, access_control.user)
    end
  end
end
