module Travis::API::V3
  class Models::Allowance
    attr_reader :subscription_type, :public_repos, :private_repos, :concurrency_limit, :user_usage, :pending_user_licenses, :id

    def initialize(subscription_type, owner_id, attributes = {})
      @subscription_type = subscription_type
      @id = owner_id
      @public_repos = attributes.fetch('public_repos', nil)
      @private_repos = attributes.fetch('private_repos', nil)
      @concurrency_limit = attributes.fetch('concurrency_limit', nil)
      @user_usage = attributes.fetch('user_usage', nil)
      @pending_user_licenses = attributes.fetch('pending_user_licenses', nil)
    end
  end
end
