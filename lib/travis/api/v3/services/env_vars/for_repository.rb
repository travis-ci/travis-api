module Travis::API::V3
  class Services::EnvVars::ForRepository < Service
    def run!
      repository = check_login_and_find(:repository)
      result find(:env_vars, repository)
    end
  end
end
