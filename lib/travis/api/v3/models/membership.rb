module Travis::API::V3
  class Models::Membership < Model
    belongs_to :user
    belongs_to :organization
  end
end
