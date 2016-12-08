module Travis::API::V3
  class Models::UserBetaFeature < Model
    belongs_to :user
    belongs_to :beta_feature

    delegate :name, :description, :feedback_url, :staff_only, to: :beta_feature

    def enabled
      !!self[:enabled]
    end
  end
end
