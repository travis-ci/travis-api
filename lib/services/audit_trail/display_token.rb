module Services
  module AuditTrail
    class DisplayToken < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      private

      def message
        "is displaying #{user.login}'s GitHub token"
      end
    end
  end
end
