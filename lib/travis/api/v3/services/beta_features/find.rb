module Travis::API::V3
  class Services::BetaFeatures::Find < Service
    def run!
      user = check_login_and_find(:user)
      not_found(false, :beta_features) unless beta_features_visible?(user)
      result query.find(user)
    end

    def beta_features_visible?(user)
      access_control.visible? user, :beta_features
    end
  end
end
