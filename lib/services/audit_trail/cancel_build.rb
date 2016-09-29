module Services
  module AuditTrail
    class CancelBuild < Struct.new(:current_user, :build)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "canceled build #{describe(build)}"
      end
    end
  end
end
