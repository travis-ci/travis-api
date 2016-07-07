module Travis::API::V3
  class Services::Settings::Find < Service
    def run!
      repository = check_login_and_find(:repository)
      find(:settings, repo)
    end
  end
end
