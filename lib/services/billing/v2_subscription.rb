# frozen_string_literal: true

module Services
  module Billing
    class V2Subscription
      def initialize(owner_id, owner_type)
        @owner_id = owner_id
        @owner_type = owner_type
        @client = Services::BillingClient.new
      end

      def subscriptions
        @client.v2_subscriptions(@owner_id, @owner_type)
      end

      def subscription(id)
        @client.v2_subscription(@owner_id, @owner_type, id)
      end

      def update_subscription(id, attributes)
        begin
          @client.update_v2_subscription(@owner_id, @owner_type, id, attributes)

          nil
        rescue => e
          e.message
        end
      end
    end
  end
end
