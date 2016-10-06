module Services
  module AuditTrail
    class RestartJob < Struct.new(:current_user, :job)
      include Services::AuditTrail::Base

      private

      def message
        "restarted job #{describe(job)}"
      end
    end
  end
end
