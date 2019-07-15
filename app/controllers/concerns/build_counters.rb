module BuildCounters
  def build_counts(owner)
    Travis::DataStores.redis.hgetall("builds:#{owner.github_id}").sort_by(&:first).map { |e| e.last.to_i }
  end

  def build_months(owner)
    Travis::DataStores.redis.hgetall("builds:#{owner.github_id}").keys.sort.map do |key|
      key.sub(/(\d{4})(\d{2})/, '\1-\2')
      # Converts "123456" to "3456-12"
    end
  end

  def builds_remaining_for(owner)
    Travis::DataStores.redis.get("trial:#{owner.login}")
  end
end