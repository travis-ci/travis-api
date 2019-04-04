module Travis::API::V3
  class Paginator
    attr_accessor :default_limit, :max_limit

    def initialize(default_limit: 25, max_limit: 100)
      @default_limit = default_limit
      @max_limit     = max_limit
    end

    def paginate(result, limit: nil, offset: nil, skip_count: false, access_control: AccessControl::Anonymous.new)
      limit &&= Integer(limit, :limit)
      limit ||= default_limit
      limit   = default_limit if limit < 0

      unless access_control.full_access?
        limit = max_limit if limit > max_limit || limit < 1
      end

      offset &&= Integer(offset, :offset)
      offset   = 0 if offset.nil? or offset < 0

      if ENV['EFFICIENT_PAGINATION_ENABLED'] == 'true'
        # TODO make id field and sort order configurable
        result.resource = result.resource.limit(limit)            unless limit  == 0
        result.resource = result.resource.where('id < ?', offset) unless offset == 0

        # TODO materialize lazily?
        result.resource = result.resource.all

        pagination_info = {
          limit:  limit,
          offset: result.resource.last&.id,
        }
      else
        if skip_count
          # this is a hack to opt into skipping the expensive
          # count query. for large collections such as builds
          # or requests this can prevent us from running really
          # bad queries.
          #
          # it's a half-way solution towards full efficient
          # pagination. we are missing the efficient offset query
          # so paging backwards will still become increasingly
          # slow.
          #
          # if a query string parameter skip_count=true is given,
          # we pretend there is another full page of results,
          # which populates `@pagination.next`.
          count = offset + (limit * 2)
        elsif ENV['PAGINATION_COUNT_CACHE_ENABLED'] == 'true'
          count = CountCache.new(result).count
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
      end

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
