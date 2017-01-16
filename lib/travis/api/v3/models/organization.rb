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

    def repositories_as_owner
      V3::Models::Repository.where(
        "repositories.owner_id = :owner_id AND repositories.owner_type = :owner_type",
        owner_id: id,
        owner_type: 'Organization'
      )
    end
  end
end
