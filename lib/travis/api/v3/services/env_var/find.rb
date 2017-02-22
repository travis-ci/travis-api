module Travis::API::V3
  class Services::EnvVar::Find < Service
    params :id, prefix: :repository
    params :id, prefix: :env_var

    def run!
      repository = check_login_and_find(:repository)
      query.find(repository).tap do |env_var|
        access_control.permissions(env_var).read! if env_var
      end
    end
  end
end
