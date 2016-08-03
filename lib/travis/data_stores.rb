module Travis
  module DataStores
    def redis
      @redis ||= Travis::RedisPool.new(Travis::Config.load.redis.to_h)
    end
    module_function :redis

    def topaz
      @topaz ||= Travis::Topaz.new(Travis::Config.topaz.url)
    end
    module_function :topaz
  end
end

