module Services
  module AuditTrail
    class CreateSubscription < Struct.new(:current_user, :subscription)
      include Services::AuditTrail::Base

      def message
        'created a subscription'
      end

      def args
        { owner: subscription.owner, plan: subscription.selected_plan }
      end
    end
  end
end
