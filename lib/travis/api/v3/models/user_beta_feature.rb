module Travis::API::V3
  class Models::UserBetaFeature < Model
    belongs_to :user
    belongs_to :beta_feature
  end
end
