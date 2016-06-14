module Travis::API::V3
  class Services::EnvVars::ForRepository < Service
    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      find(:env_vars, repository)
    end
  end
end
