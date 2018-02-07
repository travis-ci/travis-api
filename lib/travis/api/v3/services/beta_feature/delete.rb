module Travis::API::V3
  class Services::BetaFeature::Delete < Service
    def run!
      user = check_login_and_find(:user)
      not_found(false, :beta_feature) unless beta_feature_visible?(user)
      result query.delete(user)
    end

    def beta_feature_visible?(user)
      access_control.visible? user, :beta_feature
    end
  end
end
