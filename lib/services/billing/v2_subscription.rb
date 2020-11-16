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
        @client.v2_subscriptions(@owner_id)
      end

      def subscription
        if @owner_type == 'Organization'
          owner_id = Organization.find_by(id: @owner_id).users.first.id.to_s
          subscriptions = @client.v2_subscriptions(owner_id)
        else
          subscriptions = @client.v2_subscriptions(@owner_id)
        end

        subscriptions.select { |subscription| subscription.owner_id == @owner_id.to_i && subscription.owner_type == @owner_type }.first
      end

      def invoices
        sub = subscription
        sub ? @client.v2_invoices(@owner_id.to_i, subscription.id) : []
      end

      def update_subscription(id, attributes)
        @client.update_v2_subscription(@owner_id, id, attributes)

        nil
      rescue => e
        e.message
      end
    end
  end
end
