module Travis::API::V3
  class TmateStore
    # After 6 hours, we purge the token -> job_id association.
    DEBUG_JOB_EXPIRE = 6*3600

    class << self
      def register_job_id(job_id, token)
        raise ArgumentError unless job_id.present? && token.present?

        redis.multi do
          redis.set(token_key(token), job_id)
          redis.expire(token_key(token), DEBUG_JOB_EXPIRE)
        end
      end

      def find_job_id(token)
        job_id = redis.get(token_key(token))
      end

      private

        def redis
          Redis.instance
        end

        def token_key(token)
          "tmate:token:#{token}"
        end
    end
  end
end
