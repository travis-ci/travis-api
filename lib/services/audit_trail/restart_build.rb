module Services
  module AuditTrail
    class RestartBuild < Struct.new(:current_user, :build)
      include Services::AuditTrail::Base

      def message
        'restarted build'
      end

      def args
        { build_id: build.id }
      end
    end
  end
end
