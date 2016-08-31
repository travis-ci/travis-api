module JobBoost
  def existing_boost_limit(owner)
    Travis::DataStores.redis.get("scheduler.owner.limit.#{owner.login}")
  end

  def normalized_boost_time(owner)
    existing_boost_time = Travis::DataStores.redis.ttl("scheduler.owner.limit.#{owner.login}")
    if existing_boost_time <= 0 || existing_boost_time == nil
      return nil
    else
      (existing_boost_time.to_f/3600).round(2)
    end
  end

  def set_boost_limit(owner, hours, limit)
    Travis::DataStores.redis.setex("scheduler.owner.limit.#{owner.login}", (hours.to_f * 3600).to_i, limit)
  end
end
