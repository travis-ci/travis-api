module Travis::API::V3
  class Services::BetaFeatures::Find < Service
    def run!
      user = check_login_and_find(:user)
      query.find(user)
    end
  end
end
