module Travis::API::V3
  class Queries::BetaFeature < Query
    params :id, :enabled, prefix: :beta_feature

    def update(user)
      if beta_feature = Models::UserBetaFeature.find(beta_feature_id: id)
        beta_feature.update(enabled: enabled)
      else
        Models::UserBetaFeature.create(user: user, beta_feature_id: id, enabled: enabled)
      end
    end

    def delete(user)
      user.user_beta_features.destroy(id)
    end
  end
end
