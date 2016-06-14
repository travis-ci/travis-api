module Travis::API::V3
  class Services::EnvVar::Update < Service
    params :id, prefix: :repository
    params :id, :name, :value, :public, prefix: :env_var

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      query.update(repository)
    end
  end
end
