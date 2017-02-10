module Travis::API::V3
  class Models::UserBetaFeature < Model
    belongs_to :user
    belongs_to :beta_feature

    delegate :name, :description, :feedback_url, :staff_only, to: :beta_feature

    before_update :set_activations

    def enabled
      !!self[:enabled]
    end

    private

    def set_activations
      if enabled_changed?
        enabled? ? activated : deactivated
      end
    end

    def activated
      self.last_activated_at = Time.now.utc
    end

    def deactivated
      self.last_deactivated_at = Time.now.utc
    end
  end
end
