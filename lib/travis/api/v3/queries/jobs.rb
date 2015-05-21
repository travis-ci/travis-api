module Travis::API::V3
  class Queries::Jobs < Query
    PENDING = %w[started queued created]
    private_constant :PENDING

    def pending(*repos)
      for_owner(owner, state: PENDING)
    end

    def for_repos(*repos, **filters)
      Models::Job.where(repository_id: repos.map(&:id), **filters)
    end
  end
end
