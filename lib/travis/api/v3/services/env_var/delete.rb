module Travis::API::V3
  class Services::EnvVar::Delete < Service
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      env_var = find(:env_var, repository)
      access_control.permissions(env_var).write!
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token).app_id

      query.delete(repository, app_id == 2) and deleted
    end
  end
end
