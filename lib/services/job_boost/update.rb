module Services
  module JobBoost
    class Update
      attr_reader :login

      def initialize(login)
        @login = login
      end

      def call(hours, limit)
        Travis::DataStores.redis.setex("scheduler.owner.limit.#{login}", (hours.to_f * 3600).to_i, limit)
      end
    end
  end
end
