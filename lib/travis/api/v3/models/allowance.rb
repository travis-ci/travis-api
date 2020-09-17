module Travis::API::V3
  class Models::Allowance
    attr_reader :subscription_type, :public_repos, :private_repos, :concurrency_limit, :id

    def initialize(subscription_type, owner_id, attributes = {})
      @subscription_type = subscription_type
      @id = owner_id
      @public_repos = attributes.fetch('public_repos')
      @private_repos = attributes.fetch('private_repos')
      @concurrency_limit = attributes.fetch('concurrency_limit')
    end
  end
end
