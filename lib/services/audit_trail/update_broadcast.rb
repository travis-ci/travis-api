module Services
  module AuditTrail
    class UpdateBroadcast < Struct.new(:current_user, :broadcast)
      include Services::AuditTrail::Base

      def message
        "#{broadcast.expired ? 'disabled' : 'enabled'} a broadcast"
      end

      def args
        { recipient: broadcast.recipient.login, broadcast_id: broadcast.id }
      end
    end
  end
end
