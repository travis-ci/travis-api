module Services
  module AuditTrail
    class DisableRepository < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      private

      def message
        "disabled hook for #{repository.slug}"
      end
    end
  end
end
