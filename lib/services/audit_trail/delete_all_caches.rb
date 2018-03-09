module Services
  module AuditTrail
    class DeleteAllCaches < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      def message
        'deleted all caches'
      end

      def args
        { repo: repository.slug }
      end
    end
  end
end
