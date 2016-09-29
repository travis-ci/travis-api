module Services
  module AuditTrail
    class Sync < Struct.new(:current_user, :user)
      include Services::AuditTrail::Base

      private

      def message
        "triggered sync for #{user.class.to_s == 'User' ? describe(user) : user.join(', ')}"
      end
    end
  end
end
