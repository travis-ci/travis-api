module Travis::API::V3
  class Queries::BetaFeatures < Query

    def find(user)
      user_beta_features = user.user_beta_features
      ids = user_beta_features.pluck(:beta_feature_id)
      if ids.empty?
        beta_features = Models::BetaFeature.all
      else
        beta_features = Models::BetaFeature.where('id NOT IN (?)', ids)
      end
      beta_features + user_beta_features
    end
  end
end
