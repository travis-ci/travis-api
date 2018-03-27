module Services
  module AuditTrail
    class DisableRepository < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      def message
        'disabled repo hook'
      end

      def args
        { repo: repository.slug }
      end
    end
  end
end
