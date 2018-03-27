require 'travis_config'

module Travis
  module DataStores
    def redis
      @redis ||= Travis::RedisPool.new(travis_config.redis.to_h)
    end
    module_function :redis

    def travis_config
      TravisConfig.load
    end
    module_function :travis_config
  end
end
