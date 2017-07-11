module Travis::API::V3
  class Services::EnvVar::Find < Service
    params :id, prefix: :repository
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      result find(:env_var, repository)
    end
  end
end
