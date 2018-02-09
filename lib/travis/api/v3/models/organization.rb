module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships
    has_one  :subscription, as: :owner

    def repositories
      Models::Repository.where(owner_type: 'Organization', owner_id: id)
    end

    def subscription
      if Features.use_subscriptions?
        subs = Models::Subscription.where(owner_id: id, owner_type: "Organization")
        @subscription ||= subs.where(status: 'subscribed').last || subs.last
      end
    end

    alias members users
  end
end
