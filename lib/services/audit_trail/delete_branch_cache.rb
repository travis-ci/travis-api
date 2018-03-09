module Services
  module AuditTrail
    class DeleteBranchCache < Struct.new(:current_user, :repository, :branch)
      include Services::AuditTrail::Base

      def message
        'deleted branch cache'
      end

      def args
        { branch: branch, repo: repository.slug }
      end
    end
  end
end
