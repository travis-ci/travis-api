module Travis::API::V3
  class Models::V2PlanConfig
    attr_reader :id, :name, :private_repos, :starting_price, :starting_users, :plan_type,
                :private_credits, :public_credits, :addon_configs, :concurrency_limit, :available_standalone_addons

    def initialize(attrs)
      @id = attrs.fetch('id')
      @name = attrs.fetch('name')
      @private_repos = attrs.fetch('private_repos')
      @starting_price = attrs.fetch('starting_price')
      @starting_users = attrs.fetch('starting_users')
      @private_credits = attrs.fetch('private_credits')
      @public_credits = attrs.fetch('public_credits')
      @addon_configs = attrs.fetch('addon_configs')
      @plan_type = attrs.fetch('plan_type')
      @concurrency_limit = attrs.fetch('concurrency_limit')
      @available_standalone_addons = attrs.fetch('available_standalone_addons')
    end
  end
end
