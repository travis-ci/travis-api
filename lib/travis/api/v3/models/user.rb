module Travis::API::V3
  class Models::User < Model
    has_many :memberships,   dependent: :destroy
    has_many :organizations, through: :memberships
    has_many :permissions,   dependent: :destroy
    has_many :repositories,  through: :permissions
    has_many :emails,        dependent: :destroy
  end
end
