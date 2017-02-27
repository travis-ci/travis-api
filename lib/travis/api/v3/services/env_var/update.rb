module Travis::API::V3
  class Services::EnvVar::Update < Service
    params :name, :value, :public, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      env_var = find(:env_var, repository)
      access_control.permissions(env_var).write!
      result query.update(env_var)
    end
  end
end
