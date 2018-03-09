module Services
  module AuditTrail
    class DisplayToken < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      def message
        'displayed token'
      end

      def args
        { user: user.login, admin: current_user.login }
      end
    end
  end
end
