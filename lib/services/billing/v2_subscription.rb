# frozen_string_literal: true

module Services
  module Billing
    class V2Subscription
      def initialize(owner_id, owner_type)
        @owner_id = owner_id
        @owner_type = owner_type
        @search_by_owner_id = @owner_type == 'Organization' ? ::Organization.find_by(id: @owner_id).users&.first&.id&.to_s : @owner_id
        @client = Services::BillingClient.new
      end

      def subscriptions
        @client.v2_subscriptions(@owner_id)
      end

      def subscription
        subscriptions = @client.v2_subscriptions(@search_by_owner_id) if @search_by_owner_id.present?

        subscriptions.select { |subscription| subscription.owner_id == @owner_id.to_i && subscription.owner_type == @owner_type }.first  if @search_by_owner_id.present?
      end

      def invoices
        sub = subscription
        sub ? @client.v2_invoices(@search_by_owner_id.to_i, sub.id) : [] if @search_by_owner_id.present?
      end

      def plans
        @client.v2_plans(@search_by_owner_id.to_s) if @search_by_owner_id.present?
      end

      def update_subscription(id, attributes)
        @client.update_v2_subscription(@search_by_owner_id, id, attributes) if @search_by_owner_id.present?

        nil
      rescue => e
        e.message
      end

      def create_subscription(attributes)
        @client.create_v2_subscription(@search_by_owner_id, attributes) if @search_by_owner_id.present?
      end

      def create_addon(id, attributes)
        @client.create_v2_addon(@search_by_owner_id, id, attributes) if @search_by_owner_id.present?

        nil
      rescue => e
        e.message
      end
    end
  end
end
