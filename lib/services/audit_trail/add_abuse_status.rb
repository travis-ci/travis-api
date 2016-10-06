module Services
  module AuditTrail
    class AddAbuseStatus < Struct.new(:current_user, :login, :status)
      include Services::AuditTrail::Base

      private

      def message
        "marked #{login} as #{status}"
      end
    end
  end
end
