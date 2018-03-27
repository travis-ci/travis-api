module Services
  module AuditTrail
    class RemoveAbuseStatus < Struct.new(:current_user, :login, :status)
      include Services::AuditTrail::Base

      def message
        'removed abuse status'
      end

      def args
        { owner: login, status: status }
      end
    end
  end
end
