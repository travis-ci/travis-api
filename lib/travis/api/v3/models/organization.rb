module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships
    has_many :repositories, as: :owner
    has_one  :subscription, as: :owner

    def subscription
      super if Features.use_subscriptions?
    end

    alias members users
  end
end
