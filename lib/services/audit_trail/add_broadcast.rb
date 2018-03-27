module Services
  module AuditTrail
    class AddBroadcast < Struct.new(:current_user, :broadcast)
      include Services::AuditTrail::Base

      def message
        'created a broadcast'
      end

      def args
        { recipient: recipient_login, broadcast_id: broadcast.id }
      end

      def recipient
        broadcast.recipient
      end

      def recipient_login
        recipient.respond_to?(:login) ? recipient.login : recipient.name
      end
    end
  end
end
