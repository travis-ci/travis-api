module Services
  module AuditTrail
    class JobBoost < Struct.new(:current_user, :hours, :limit)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "set job boost to #{limit}, expires after #{hours} hours"
      end
    end
  end
end
