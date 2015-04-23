module Travis::API::V3
  module Features
    extend self

    def use_subscriptions?
      Models::Subscription.table_exists?
    end
  end
end
