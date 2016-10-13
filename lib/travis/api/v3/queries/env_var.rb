module Travis::API::V3
  class Queries::EnvVar < Query
    params :id, :name, :value, :public, prefix: :env_var

    def find(repository)
      repository.env_vars.find(id)
    end

    def update(repository)
      if env_var = find(repository)
        env_var.update(env_var_params)
        repository.env_vars.add(env_var)
        env_var
      end
    end

    def delete(repository)
      repository.env_vars.destroy(id)
    end
  end
end
