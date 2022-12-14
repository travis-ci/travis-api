module Services
  module AuditTrail
    class BecomeAs < Struct.new(:current_user, :login)
      include Services::AuditTrail::Base

      def message
        'used log in as'
      end

      def args
        { user: login }
      end
    end
  end
end
