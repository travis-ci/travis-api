module Travis::API::V3
  class Services::EnvVar::Delete < Service
    params :id, prefix: :repository
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).change_env_vars!
      query.delete(repository) and deleted
    end
  end
end
