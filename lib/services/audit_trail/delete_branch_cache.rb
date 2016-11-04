module Services
  module AuditTrail
    class DeleteBranchCache < Struct.new(:current_user, :repository, :branch)
      include Services::AuditTrail::Base

      private

      def message
        "deleted #{branch} branch cache for #{repository} repository"
      end
    end
  end
end