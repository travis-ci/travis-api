module Travis::API::V3
  class Services::SshKey::Find < Service
    def run!
      repository = check_login_and_find(:repository)
      query.find(repository)
    end
  end
end
