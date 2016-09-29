module Services
  module AuditTrail
    class TrialBuilds < Struct.new(:current_user, :owner, :trial_builds)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "reset #{owner.login}'s trial to #{trial_builds} builds"
      end
    end
  end
end
