module Travis::API::V3
  class Models::Allowance
    attr_reader :public_repos, :private_repos, :concurrency_limit

    def initialize(attributes = {})
      @public_repos = attributes.fetch('public_repos')
      @private_repos = attributes.fetch('private_repos')
      @concurrency_limit = attributes.fetch('concurrency_limit')
    end
  end
end
