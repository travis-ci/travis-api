module Travis
  def redis
    @redis ||= Travis::RedisPool.new(Travis::Config.load.redis.to_h)
  end
  module_function :redis
end

