module Services
  module TrialBuilds
    class Update
      def initialize(owner, current_user)
        @owner = owner
        @current_user = current_user
      end

      def call(builds_remaining, previous_builds)
        Travis::DataStores.redis.set("trial:#{@owner.login}", builds_remaining)
        Services::EventLogs::Add.new(@current_user, "reset #{@owner.login}'s trial to #{builds_remaining} builds").call
        update_topaz(@owner, builds_remaining, previous_builds)
      end

      private

      def update_topaz(owner, builds_remaining, previous_builds)
        event = {
          timestamp: Time.now,
          owner: {
            id: owner.id,
            name: owner.name,
            login: owner.login,
            type: owner.class.name
          },
          data: {
            trial_builds_added: builds_remaining.to_i,
            previous_builds: previous_builds.to_i
          },
          type: :trial_builds_added
        }
        Travis::DataStores.topaz.update(event)
      end
    end
  end
end
