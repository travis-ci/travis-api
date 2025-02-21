module Travis::API::V3
  class Queries::AccountEnvVar < Query

    def find(params)
      Models::AccountEnvVar.where(owner_type: params['owner_type'], owner_id: params['owner_id'])
    end

    def create(account_env_var)
      raise UnprocessableEntity, "'#{params['name']}' environment variable already exists." unless Models::AccountEnvVar.where(name: params['name'], owner_id: params['owner_id'], owner_type: params['owner_type']).count.zero?
      account_env_var.save_account_env_var!(account_env_var)
    end

    def delete(account_env_var)
      account_env_var.delete(account_env_var)
    end
  end
end
