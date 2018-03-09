module Services
  module AuditTrail
    class ResetTwoFa < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      def message
        'reset two-factor auth secret'
      end

      def args
        { user: user.login }
      end
    end
  end
end
