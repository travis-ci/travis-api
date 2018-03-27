module Services
  module AuditTrail
    class CancelBuild < Struct.new(:current_user, :build)
      include Services::AuditTrail::Base

      def message
        'cancelled build'
      end

      def args
        { build_id: build.id }
      end
    end
  end
end
