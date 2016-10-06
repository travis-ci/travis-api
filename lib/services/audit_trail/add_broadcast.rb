module Services
  module AuditTrail
    class AddBroadcast < Struct.new(:current_user, :broadcast)
      include Services::AuditTrail::Base

      private

      def message
        "created a broadcast for #{describe(broadcast.recipient)}: \"#{broadcast.message}\""
      end
    end
  end
end
