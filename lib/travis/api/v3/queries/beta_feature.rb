module Travis::API::V3
  class Queries::BetaFeature < Query
    params :id, :enabled, prefix: :beta_feature

    def find
      Models::BetaFeature.find_by_id(id)
    end

    def update(user)
      raise EntityMissing, 'beta_feature not found'.freeze unless find

      if user_beta_feature = user.user_beta_features.where(beta_feature_id: id, ).first
        user_beta_feature.update_attribute(:enabled, enabled)
        user_beta_feature
      else
        Models::UserBetaFeature.create(user: user, beta_feature_id: id, enabled: enabled)
      end
    end

    def delete(user)
      user.user_beta_features.where(beta_feature_id: id).first.try(:destroy)
    end
  end
end
