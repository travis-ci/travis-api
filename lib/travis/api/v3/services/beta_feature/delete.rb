module Travis::API::V3
  class Services::BetaFeature::Delete < Service
    def run!
      user = check_login_and_find(:user)
      query.delete(user)
    end
  end
end
