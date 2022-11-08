module Services
  module AuditTrail
    class Sync < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      def message
        'triggered sync'
      end

      def args
        { user_login: Array(user).join(',') }
      end
    end
  end
end
