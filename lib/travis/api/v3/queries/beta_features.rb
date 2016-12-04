module Travis::API::V3
  class Queries::BetaFeatures < Query

    def find(user)
      user_beta_features = user.beta_features
      beta_features = BetaFeature.where.not(id: user_beta_features.map(&:beta_feature_id))
      beta_features + user_beta_features
    end
  end
end
