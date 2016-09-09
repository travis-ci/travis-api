module Services
  module JobBoost
    class Update
      def initialize(login, current_user)
        @login = login
        @current_user = current_user
      end

      def call(hours, limit)
        Travis::DataStores.redis.setex("scheduler.owner.limit.#{@login}", (hours.to_f * 3600).to_i, limit)
        Services::EventLogs::Add.new(@current_user, "set job boost to #{limit}, expires after #{hours} hours").call
      end
    end
  end
end
