module SubscriptionsHelper
  def format_plan(plan)
    plan.gsub(/-/, ' ').remove('travis ci ')
  end

  def format_subscription(subscription)
    if subscription.active?
      "active, #{format_plan(subscription.selected_plan) || "unknown plan"}, expires #{subscription.valid_to.to_date}"
    elsif subscription.expired?
      "inactive, expired #{subscription.valid_to.to_date}"
    else
      "not active"
    end
  end
end
