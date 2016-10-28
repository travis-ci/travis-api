module Services
  module AuditTrail
    class ResetTwoFa < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      private

      def message
        "reset #{user.login}'s two-factor auth secret"
      end
    end
  end
end
