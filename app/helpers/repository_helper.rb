module RepositoryHelper
  def has_trace_rollout_repos?(repository)
    Travis::DataStores.redis.sismember('trace.rollout.repos', repository.slug)
  end

  def vcs_repo_url(repo)
    Travis::Providers.get(repo.vcs_type).new(repo).repo_link
  end
end
