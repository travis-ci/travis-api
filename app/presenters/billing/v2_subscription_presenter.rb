# frozen_string_literal: true

module Billing
  class V2SubscriptionPresenter < SimpleDelegator
    def initialize(subscription, page, view)
      @subscription = subscription
      @page = page
      @view = view

      super(@subscription)
    end

    def source_options
      Travis::Models::Billing::V2Subscription::SOURCES.map { |source| [ source.capitalize, source ] }
    end

    def addon_status_options
      Travis::Models::Billing::V2AddonUsage::STATUSES.map { |status| [ status.capitalize, status ] }
    end

    def addon_name_options(type, is_free)
      (@subscription.plan_config[:available_standalone_addons] + @subscription.plan_config[:addon_configs]).uniq.map { |addon_config| [ addon_config[:name], addon_config[:id] ] if addon_config[:type] == type && addon_config[:free] == is_free }.compact
    end

    def created_at
      h.format_time(Time.parse(@subscription.created_at))
    end

    def valid_to
      @subscription.valid_to.presence && h.format_time(Time.parse(@subscription.valid_to), false)
    end

    def plan_changes
      @subscription.changes.sort { |a, b| b.id.to_i - a.id.to_i }.map { |change| Billing::V2PlanChangePresenter.new(change) }.paginate(page: @page, per_page: 5)
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
