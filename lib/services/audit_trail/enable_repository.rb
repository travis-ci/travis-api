module Services
  module AuditTrail
    class EnableRepository < Struct.new(:current_user, :repository)
      include ApplicationHelper
      include Services::AuditTrail

      private

      def message
        "enabled hook for #{repository.slug}"
      end
    end
  end
end
