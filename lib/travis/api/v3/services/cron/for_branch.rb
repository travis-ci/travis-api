module Travis::API::V3
  class Services::Cron::ForBranch < Service

    def run!
      repo = find(:repository)
      result query.find_for_branch(find(:branch, repo))
    end
  end
end
