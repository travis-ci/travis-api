module Services
  module AuditTrail
    class RemoveAbuseStatus < Struct.new(:current_user, :login, :status)
      include Services::AuditTrail::Base

      private

      def message
        "removed #{login} as #{status}"
      end
    end
  end
end
