module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships
    has_many :repositories, as: :owner
  end
end
