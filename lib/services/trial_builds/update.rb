module Services
  module TrialBuilds
    class Update
      def initialize(owner, current_user)
        @owner = owner
        @current_user = current_user
      end

      def call(builds_remaining, previous_builds)
        Travis::DataStores.redis.set("trial:#{@owner.login}", builds_remaining)
        Services::AuditTrail::TrialBuilds.new(@current_user, @owner, builds_remaining).call
      end

    end
  end
end
