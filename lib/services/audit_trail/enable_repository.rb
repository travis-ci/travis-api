module Services
  module AuditTrail
    class EnableRepository < Struct.new(:current_user, :repository)
      include Services::AuditTrail::Base

      def message
        'enabled repo hook'
      end

      def args
        { repo: repository.slug }
      end
    end
  end
end
