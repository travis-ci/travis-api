module Travis::API::V3
  class Services::EnvVar::Delete < Service
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      env_var = find(:env_var, repository)
      access_control.permissions(env_var).write!
      query.delete(repository) and no_content
    end
  end
end
