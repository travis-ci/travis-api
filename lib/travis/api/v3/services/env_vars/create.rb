module Travis::API::V3
  class Services::EnvVars::Create < Service
    params :name, :value, :public, :branch, prefix: :env_var
    result_type :env_var

    def run!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).create_env_var!
      return repo_migrated if migrated?(repository)
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token).app_id

      env_var = query(:env_vars).create(repository, app_id == 2)
      result(env_var, status: 201)
    end
  end
end
