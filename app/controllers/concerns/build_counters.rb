module BuildCounters
  def build_counts(owner)
    Travis::DataStores.redis.hgetall("builds:#{owner.github_id}").sort_by(&:first).map { |e| e.last.to_i }
  end

  def builds_provided_for(owner)
    Travis::DataStores.topaz.builds_provided_for(owner.id).try(:to_i)
  end
end