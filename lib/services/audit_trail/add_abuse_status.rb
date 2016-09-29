module Services
  module AuditTrail
    class AddAbuseStatus < Struct.new(:current_user, :login, :status)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "marked #{login} as #{status}"
      end
    end
  end
end
