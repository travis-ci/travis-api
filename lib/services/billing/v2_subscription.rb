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
        return [] unless travis_pro?

        @client.v2_subscriptions(@owner_id)
      end

      def subscription
        return unless travis_pro?

        @client.v2_subscription(@owner_type, @owner_id)
      end

      def invoices
        return [] unless travis_pro?

        sub = subscription
        sub ? @client.v2_invoices(@search_by_owner_id.to_i, sub.id) : [] if @search_by_owner_id.present?
      end

      def plans
        return [] unless travis_pro?

        @client.v2_plans(@owner_id.to_s)
      end

      def update_subscription(id, attributes)
        return unless travis_pro?

        @client.update_v2_subscription(id, attributes)

        nil
      rescue => e
        e.message
      end

      def create_subscription(attributes)
        return unless travis_pro?

        @client.create_v2_subscription(@search_by_owner_id, attributes) if @search_by_owner_id.present?
      end

      def create_addon(id, attributes)
        return unless travis_pro?

        @client.create_v2_addon(@search_by_owner_id, id, attributes) if @search_by_owner_id.present?

        nil
      rescue => e
        e.message
      end

      def update_auto_refill(id, attributes)
        return unless travis_pro?

        @client.update_auto_refill(@search_by_owner_id, id, attributes) if @search_by_owner_id.present?

        nil
      rescue => e
        e.message
      end

      def travis_pro?
        travis_config&.travis_pro
      end

      def travis_config
        Rails.configuration.travis_config
      end
    end
  end
end
