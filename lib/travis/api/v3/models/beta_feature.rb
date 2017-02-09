module Travis::API::V3
  class Models::BetaFeature < Model
    validates :name, uniqueness: true

    def enabled
      !!default_enabled
    end
  end
end
