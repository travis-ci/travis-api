module Travis::API::V3
  class Services::Cron::ForBranch < Service

    def run!
      repo = find(:repository)
      raise InsufficientAccess unless Travis::Features.owner_active?(:cron, repo.owner)
      query.find_for_branch(find(:branch, repo))
    end
  end
end
