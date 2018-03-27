module Services
  module AuditTrail
    class DeleteLastBuild < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      def message
        'dropped last build reference'
      end

      def args
        { repo: repository.slug }
      end
    end
  end
end
