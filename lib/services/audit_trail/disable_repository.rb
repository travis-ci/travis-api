module Services
  module AuditTrail
    class DisableRepository < Struct.new(:current_user, :repository)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "disabled hook for #{repository.slug}"
      end
    end
  end
end
