module Travis::API::V3
  class Models::BetaFeature < Model
    validates :name, uniqueness: true
  end
end
