module Travis::API::V3
  class Services::SshKey::Create < Service
    def run!
      repository = check_login_and_find(:repository)
      ssh_key = query.regenerate(repository)
      result(:ssh_key, ssh_key, status: 201)
    end
  end
end
