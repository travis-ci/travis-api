module Services
  module AuditTrail
    class CreateSubscription < Struct.new(:current_user, :subscription)
      include Services::AuditTrail::Base
      include SubscriptionsHelper

      private

      def message
        "created a #{format_plan(subscription.selected_plan)} subscription for #{describe(subscription.owner)}"
      end
    end
  end
end
