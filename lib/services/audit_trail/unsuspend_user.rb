module Services
  module AuditTrail
    class UnsuspendUser < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      def message
        'unsuspended user'
      end

      def args
        { user_id: user.id, user_login: user.login }
      end
    end
  end
end
