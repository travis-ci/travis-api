module Services
  module TrialBuilds
    class Update
      def initialize(owner, current_user)
        @owner = owner
        @current_user = current_user
      end

      def call(builds_allowed)
        @owner.latest_trial && @owner.latest_trial.trial_allowances.create!(
          creator: current_user,
          builds_allowed: builds_allowed,
          builds_remaining: builds_allowed
        )
        Services::AuditTrail::TrialBuilds.new(@current_user, @owner, builds_allowed).call
      end
    end
  end
end
