module Services
  module AuditTrail
    class RestartBuild < Struct.new(:current_user, :build)
      include Services::AuditTrail::Base

      private

      def message
        "restarted build #{describe(build)}"
      end
    end
  end
end
