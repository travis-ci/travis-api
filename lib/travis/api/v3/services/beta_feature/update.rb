module Travis::API::V3
  class Services::BetaFeature::Update < Service
    params :id, prefix: :user
    params :id, :enabled, prefix: :beta_feature

    def run!
      user = check_login_and_find(:user)
      not_found(false, :beta_feature) unless beta_feature_visible?(user)
      result query.update(user)
    end

    def beta_feature_visible?(user)
      access_control.visible? user, :beta_feature
    end
  end
end
