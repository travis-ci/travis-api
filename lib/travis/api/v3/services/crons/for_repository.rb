module Travis::API::V3
  class Services::Crons::ForRepository < Service
    paginate

    def run!
      repo = find(:repository)
      raise InsufficientAccess unless Travis::Features.owner_active?(:cron, repo.owner)
      query.find(repo)
    end
  end
end
