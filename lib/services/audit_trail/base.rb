module Services
  module AuditTrail
    module Base
      include ApplicationHelper

      def call
        return if Rails.env.development?

        redis.lpush("admin-v2:logs", log)
        redis.ltrim("admin-v2:logs", 0, 100)
      end

      private

      def admin
        current_user ? current_user.name : 'Unknown user'
      end

      def log
        "<time>#{Time.now.utc.to_s}</time> #{admin} #{message}."
      end

      def redis
        Travis::DataStores.redis
      end
    end
  end
end
