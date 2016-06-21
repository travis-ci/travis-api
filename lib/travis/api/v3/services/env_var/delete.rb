module Travis::API::V3
  class Services::EnvVar::Delete < Service
    params :id, prefix: :repository
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      query.delete(repository)
    end
  end
end
