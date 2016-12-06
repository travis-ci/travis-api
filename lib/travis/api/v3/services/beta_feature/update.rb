module Travis::API::V3
  class Services::BetaFeature::Update < Service
    params :id, prefix: :user
    params :id, :enabled, prefix: :beta_feature

    def run!
      user = check_login_and_find(:user)
      query.update(user)
    end
  end
end
