module Travis::API::V3
  class Services::EnvVars::Create < Service
    params :id, prefix: :repository
    params :id, :name, :value, :public, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      env_var = query(:env_vars).create(repository)
      result(:env_var, env_var, status: 201)
    end
  end
end
