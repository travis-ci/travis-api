require 'redis'
require 'multi_json'

module Travis
  module Notification
    module Publisher
      class Redis
        extend Exceptions::Handling
        attr_accessor :redis, :ttl

        def initialize(options = {})
          @redis = options[:redis] || ::Redis.connect(url: Travis.config.redis.url)
          @ttl   = options[:ttl]   || 10
        end

        def publish(event)
          event = filter(event)
          payload = MultiJson.encode(event)
          # list = 'events:' << event[:uuid]
          list = 'events'

          redis.publish list, payload

          # redis.pipelined do
          #   redis.publish list, payload
          #   redis.multi do
          #     redis.persist(list)
          #     redis.rpush(list, payload)
          #     redis.expire(list, ttl)
          #   end
          # end
        end
        rescues :publish, from: Exception

        def filter(value)
          case value
          when Array
            value.map { |value| filter(value) }
          when Hash
            value.inject({}) { |hash, (key, value)| hash.merge(key => filter(value)) }
          when String, Numeric, TrueClass, FalseClass, NilClass
            value
          else
            nil
          end
        end
      end
    end
  end
end
