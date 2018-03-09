module Services
  module AuditTrail
    class JobBoost < Struct.new(:current_user, :hours, :limit)
      include Services::AuditTrail::Base

      def message
        'set job boost'
      end

      def args
        { limit: limit, hours: hours }
      end
    end
  end
end
