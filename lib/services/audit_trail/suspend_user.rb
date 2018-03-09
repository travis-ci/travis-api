module Services
  module AuditTrail
    class SuspendUser < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      def message
        'suspended user'
      end

      def args
        { user_id: user.id, user_login: user.login }
      end
    end
  end
end
