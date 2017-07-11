module Travis::API::V3
  class Services::SslKey::Find < Service
    def run!
      repository = check_login_and_find(:repository)
      result(query.find(repository) || not_found(false, :key_pair))
    end
  end
end
