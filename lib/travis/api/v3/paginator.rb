require 'digest'
require 'travis/honeycomb'

module Travis::API::V3
  class Paginator
    attr_accessor :default_limit, :max_limit

    def initialize(default_limit: 25, max_limit: 100)
      @default_limit = default_limit
      @max_limit     = max_limit
    end

    def paginate(result, limit: nil, offset: nil, access_control: AccessControl::Anonymous.new)
      limit &&= Integer(limit, :limit)
      limit ||= default_limit
      limit   = default_limit if limit < 0

      unless access_control.full_access?
        limit = max_limit if limit > max_limit || limit < 1
      end

      offset &&= Integer(offset, :offset)
      offset   = 0 if offset.nil? or offset < 0

      if ENV['PAGINATION_COUNT_CACHE_ENABLED'] == 'true'
        count_query_hash = Digest::SHA1.hexdigest(result.resource.to_sql)
        cache_key = "api:count_query:#{count_query_hash}"
        count = Travis.redis.get(cache_key)&.to_i
        
        if count
          Travis::Honeycomb.context.add('pagination.count_cache.hit', 1)
        else
          ttl = ENV['PAGINATION_COUNT_CACHE_TTL']&.to_i || 60*60*24
          threshold = ENV['PAGINATION_COUNT_CACHE_THRESHOLD']&.to_i || 100

          count = result.resource.count(:all)
          if count >= threshold
            Travis.redis.setex(cache_key, ttl, count)
            Travis::Honeycomb.context.add('pagination.count_cache.miss', 1)
          else
            Travis::Honeycomb.context.add('pagination.count_cache.bypass', 1)
          end
        end
      else
        count = result.resource.count(:all)
      end

      result.resource = result.resource.limit(limit)   unless limit  == 0
      result.resource = result.resource.offset(offset) unless offset == 0

      pagination_info = {
        limit:  limit,
        offset: offset,
        count:  count,
      }

      result.meta_data[:pagination] = pagination_info
      result
    end

    def Integer(value, key)
      super(value)
    rescue ArgumentError
      raise WrongParams, "#{key} must be an integer"
    end
  end
end
