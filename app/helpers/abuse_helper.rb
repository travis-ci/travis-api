module AbuseHelper
  def abuse_name(abuse)
    case abuse.level
    when Abuse::LEVEL_OFFENDER then 'offender'
    when Abuse::LEVEL_FISHY then 'fishy'
    else ''
    end
  end

  def trusted?(owner)
    Travis::DataStores.redis.sismember('abuse:trusted', "#{owner.class.name}:#{owner.id}")
  end

  def not_fishy?(owner)
    Travis::DataStores.redis.sismember('abuse:not_fishy', "#{owner.class.name}:#{owner.id}")
  end

  def offender?(owner)
    Travis::DataStores.redis.sismember('abuse:offenders', "#{owner.class.name}:#{owner.id}")
  end
end
