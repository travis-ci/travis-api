# frozen_string_literal: true

module Billing
  class V2PlanChangePresenter < SimpleDelegator
    def initialize(plan_change)
      @plan_change = plan_change

      super(plan_change)
    end

    def human_changes
      changes = []

      if @plan_change.plan_changes.present?
        @plan_change.plan_changes.each do |field_name, field_values|
          changes << field_name_change('plan', field_name, field_values.first, field_values.last)
        end
      end

      if @plan_change.addon_changes.present?
        @plan_change.addon_changes.each do |addon_change|
          addon_change[:changes].each do |field_name, field_values|
            changes << field_name_change("addon with ID #{addon_change[:id]}", field_name, field_values.first, field_values.last)
          end
        end
      end

      changes
    end

    private

    def field_name_change(entity, field_name, old_value, new_value)
      "#{entity.capitalize} #{field_name} changed from <strong>#{old_value.presence || '""'}</strong> to <strong>#{new_value.presence || '""'}</strong>".html_safe
    end
  end
end
