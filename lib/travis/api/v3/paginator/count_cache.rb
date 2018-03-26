require 'digest'
require 'travis/honeycomb'

module Travis::API::V3
  class Paginator
    class CountCache
      attr_accessor :result

      def initialize(result)
        @result = result
      end

      def count
        count = Travis.redis.get(cache_key)&.to_i

        if count
          Travis::Honeycomb.context.add('pagination.count_cache.hit', 1)
        else
          count = count_upstream
          if count >= threshold
            Travis.redis.setex(cache_key, ttl, count)
            Travis::Honeycomb.context.add('pagination.count_cache.miss', 1)
          else
            Travis::Honeycomb.context.add('pagination.count_cache.bypass', 1)
          end
        end

        Travis::Honeycomb.context.add('pagination.count_cache.count', count)

        count
      end

      def count_upstream
        result.resource.count(:all)
      end

      def cache_key
        "api:count_query:#{query_hash}"
      end

      def query_hash
        Digest::SHA1.hexdigest(result.resource.to_sql)
      end

      def ttl
        ENV['PAGINATION_COUNT_CACHE_TTL']&.to_i || 60*60*24
      end

      def threshold
        ENV['PAGINATION_COUNT_CACHE_THRESHOLD']&.to_i || 100
      end
    end
  end
end
