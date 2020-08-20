module Travis::API::V3
  class Models::V2PlanConfig
    attr_reader :id, :name, :private_repos, :default_addons, :starting_price, :starting_users

    def initialize(attrs)
      @id = attrs.fetch('id')
      @name = attrs.fetch('name')
      @private_repos = attrs.fetch('private_repos')
      @default_addons = attrs.fetch('default_addons')
      @starting_price = attrs.fetch('starting_price')
      @starting_users = attrs.fetch('starting_users')
    end
  end
end
