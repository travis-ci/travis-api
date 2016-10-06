module Services
  module AuditTrail
    class CancelJob < Struct.new(:current_user, :job)
      include Services::AuditTrail::Base

      private

      def message
        "canceled job #{describe(job)}"
      end
    end
  end
end
