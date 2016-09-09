module Services
  module AuditTrail
    class Add
      def initialize(current_user, message)
        @message = message
        @current_user = current_user
      end

      def call
        return if Rails.env.development?

        redis.lpush("admin-v2:logs", log)
        redis.ltrim("admin-v2:logs", 0, 100)
      end

      private

      def log
        "<time>#{Time.now.utc.to_s}</time> #{@current_user ? @current_user.name : 'Unknown user'} #{@message}."
      end

      def redis
        Travis::DataStores.redis
      end
    end
  end
end
