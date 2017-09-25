module Services
  module AuditTrail
    class TrialBuilds < Struct.new(:current_user, :owner, :builds_allowed)
      include Services::AuditTrail::Base

      private

      def message
        "added #{builds_allowed} trial builds for #{owner.login}"
      end
    end
  end
end
