module Services
  module AuditTrail
    class CancelJob < Struct.new(:current_user, :job)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "canceled job #{describe(job)}"
      end
    end
  end
end
