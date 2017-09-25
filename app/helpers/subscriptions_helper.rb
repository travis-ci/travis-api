module SubscriptionsHelper
  def format_plan(plan)
    plan.gsub(/-/, ' ').remove('travis ci ')
  end

  def format_price(amount)
    number_to_currency(amount.to_f/100)
  end

  def format_subscription(subscription)
    if subscription.active?
      "active, #{format_plan(subscription.selected_plan) || "unknown plan"}, expires #{subscription.valid_to.to_date}"
    elsif subscription.expired?
      "inactive, #{format_plan(subscription.selected_plan) || "unknown plan"}, expired #{subscription.valid_to.to_date}"
    else
      "not active"
    end
  end
end
