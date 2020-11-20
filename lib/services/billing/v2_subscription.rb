# frozen_string_literal: true

module Services
  module Billing
    class V2Subscription
      def initialize(owner_id, owner_type)
        @owner_id = owner_id
        @owner_type = owner_type
        @search_by_owner_id = @owner_type == 'Organization' ? Organization.find_by(id: @owner_id).users.first.id.to_s : @owner_id
        @client = Services::BillingClient.new
      end

      def subscriptions
        @client.v2_subscriptions(@owner_id)
      end

      def subscription
        subscriptions = @client.v2_subscriptions(@search_by_owner_id)

        subscriptions.select { |subscription| subscription.owner_id == @owner_id.to_i && subscription.owner_type == @owner_type }.first
      end

      def invoices
        sub = subscription
        sub ? @client.v2_invoices(@search_by_owner_id.to_i, sub.id) : []
      end

      def plans
        @client.v2_plans(@search_by_owner_id.to_s)
      end

      def update_subscription(id, attributes)
        @client.update_v2_subscription(@search_by_owner_id, id, attributes)

        nil
      rescue => e
        e.message
      end

      def create_subscription(attributes)
        @client.create_v2_subscription(@search_by_owner_id, attributes)
      end

      def create_addon(id, addon_config_id)
        @client.create_v2_addon(@search_by_owner_id, id, addon_config_id)

        nil
      rescue => e
        e.message
      end
    end
  end
end
