module Travis::API::V3
  class Queries::EnvVar < Query
    params :id, :name, :value, :public, prefix: :env_var

    def find(repository)
      repository.env_vars.find(id)
    end

    def update(env_var)
      env_var.update(env_var_params)
      env_var.repository.env_vars.add(env_var)
      env_var
    end

    def delete(repository)
      repository.env_vars.destroy(id)
    end
  end
end
