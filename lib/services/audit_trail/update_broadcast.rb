module Services
  module AuditTrail
    class UpdateBroadcast < Struct.new(:current_user, :broadcast)
      include Services::AuditTrail::Base

      private

      def message
        "#{broadcast.expired ? 'disabled' : 'enabled'} a broadcast for #{describe(broadcast.recipient)}: \"#{broadcast.message}\""
      end
    end
  end
end
