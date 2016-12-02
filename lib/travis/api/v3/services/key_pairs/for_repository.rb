module Travis::API::V3
  class Services::KeyPairs::ForRepository < Service
    def run!
      repository = check_login_and_find(:repository)  
      repository.key_pairs
    end
  end
end
