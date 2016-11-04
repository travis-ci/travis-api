module Services
  module AuditTrail
    class DeleteAllCaches < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      private

      def message
        "deleted all caches for #{repository} repository"
      end
    end
  end
end