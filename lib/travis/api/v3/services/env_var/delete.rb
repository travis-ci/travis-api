module Travis::API::V3
  class Services::EnvVar::Delete < Service
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      env_var = find(:env_var, repository)
      access_control.permissions(env_var).write!
      query.delete(repository) and deleted
    end
  end
end
