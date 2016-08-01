require 'travis/config'

uri = Travis::Config.load.redis.to_h

Redis.current = Travis::RedisPool.new(uri)