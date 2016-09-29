module Services
  module AuditTrail
    class AddBroadcast < Struct.new(:current_user, :broadcast)
      include Services::AuditTrail::Base

      private

      def message
        "created a broadcast for #{recipient}: \"#{broadcast.message}\""
      end

      def recipient
        broadcast.recipient ? describe(broadcast.recipient) : 'everybody'
      end
    end
  end
end
