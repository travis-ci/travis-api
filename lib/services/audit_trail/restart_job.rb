module Services
  module AuditTrail
    class RestartJob < Struct.new(:current_user, :job)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "restarted job #{describe(job)}"
      end
    end
  end
end
