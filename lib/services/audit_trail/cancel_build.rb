module Services
  module AuditTrail
    class CancelBuild < Struct.new(:current_user, :build)
      include Services::AuditTrail::Base

      private

      def message
        "canceled build #{describe(build)}"
      end
    end
  end
end
