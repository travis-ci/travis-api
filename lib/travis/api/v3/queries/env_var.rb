module Travis::API::V3
  class Queries::EnvVar < Query
    params :id, :name, :value, :public, :branch, prefix: :env_var

    def find(repository)
      repository.env_vars.find(id)
    end

    def update(env_var, from_admin = false)
      env_vars = env_var.repository.env_vars
      env_vars.user = env_var.repository.user_settings.user
      env_vars.change_source = 'travis-api' unless from_admin
      env_var.update(env_var_params)
      env_vars.add(env_var)

      env_var
    end

    def delete(repository, from_admin = false)
      env_vars = repository.env_vars
      env_vars.user = repository.user_settings.user
      env_vars.change_source = 'travis-api' unless from_admin
      env_vars.destroy(id)
    end
  end
end
