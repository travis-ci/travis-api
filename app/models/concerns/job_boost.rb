module JobBoost
  def existing_boost_limit
    Travis::DataStores.redis.get("scheduler.owner.limit.#{login}")
  end

  def normalized_boost_time
    existing_boost_time = Travis::DataStores.redis.ttl("scheduler.owner.limit.#{login}")
    if existing_boost_time <= 0 || existing_boost_time == nil
      return nil
    else
      (existing_boost_time.to_f/3600).round(2)
    end
  end
end
