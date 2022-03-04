module Services
  module AuditTrail
    module Base
      include ApplicationHelper

      def message
        raise NotImplementedError
      end

      def args
        {}
      end

      def call
        # return if Rails.env.development?
        redis.lpush("admin-v2:logs", log)
        redis.ltrim("admin-v2:logs", 0, 100)
      end

      private

      def admin_id
        current_user ? current_user.id : 0
      end

      def admin_login
        current_user ? current_user.login : '_unknown_'
      end

      def fmt_args
        args.map { |k, v| " #{k}=#{v}" }.join ''
      end

      def attrs
        ['info', Time.now.utc.iso8601, admin_id, admin_login, message, fmt_args]
      end

      def log
        'level=%s time=%s admin_id=%s admin_login=%s message="%s"%s' % attrs
      end

      def redis
        Travis::DataStores.redis
      end
    end
  end
end
