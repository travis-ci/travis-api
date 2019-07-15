module RepositoryHelper
  def has_trace_rollout_repos?(repository)
    Travis::DataStores.redis.sismember('trace.rollout.repos', repository.slug)
  end
end
