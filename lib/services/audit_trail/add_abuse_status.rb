module Services
  module AuditTrail
    class AddAbuseStatus < Struct.new(:current_user, :login, :status)
      include Services::AuditTrail::Base

      def message
        'added abuse status'
      end

      def args
        { owner: login, status: status }
      end
    end
  end
end
