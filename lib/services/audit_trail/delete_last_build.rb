module Services
  module AuditTrail
    class DeleteLastBuild < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      private

      def message
        "dropped last build reference for #{repository.slug}"
      end
    end
  end
end
