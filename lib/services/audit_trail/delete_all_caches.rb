module Services
  module AuditTrail
    class DeleteAllCaches < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      private

      def message
        "deleted all caches for #{repository.slug}"
      end
    end
  end
end