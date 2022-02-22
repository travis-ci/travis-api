# frozen_string_literal: true

module Billing
  class V2SubscriptionPresenter < SimpleDelegator
    def initialize(subscription, page, view)
      @subscription = subscription
      @page = page
      @view = view

      super(@subscription)
    end

    def addon_status_options
      Travis::Models::Billing::V2AddonUsage::STATUSES.map { |status| [ status.capitalize, status ] }
    end

    def status_options
      Travis::Models::Billing::V2Subscription::STATUSES.map { |status| [ status.capitalize, status ] }
    end

    def addon_name_options(type, is_free)
      (@subscription.plan_config[:all_available_addons] + @subscription.plan_config[:addon_configs]).uniq.map { |addon_config| [ addon_config[:name], addon_config[:id] ] if addon_config[:type] == type && addon_config[:free] == is_free }.compact
    end

    def plan_options
      v2_service = Services::Billing::V2Subscription.new(@subscription.owner_id, @subscription.owner_type)
      v2_service.plans.map { |plan_config| [plan_config.name, plan_config.id] }
    end

    def created_at
      Time.parse(@subscription.created_at)
    end

    def valid_to
      @subscription.valid_to.presence && h.format_time(Time.parse(@subscription.valid_to), false)
    end

    def plan_changes
      @subscription.changes.sort { |a, b| b.id.to_i - a.id.to_i }.map { |change| Billing::V2PlanChangePresenter.new(change) }.paginate(page: @page, per_page: 25)
    end

    def grouped_addons
      @subscription.supported_addons.group_by(&:type)
    end

    private

    def h
      @view.view_context
    end
  end
end
