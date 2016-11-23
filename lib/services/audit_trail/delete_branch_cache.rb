module Services
  module AuditTrail
    class DeleteBranchCache < Struct.new(:current_user, :repository, :branch)
      include Services::AuditTrail::Base

      private

      def message
        "deleted the #{branch} cache for #{repository.slug}"
      end
    end
  end
end