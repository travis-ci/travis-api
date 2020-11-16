module SubscriptionsHelper
  def format_plan(plan)
    plan.gsub(/-/, ' ').remove('travis ci ') if plan
  end

  def format_price(amount)
    number_to_currency(amount.to_f/100)
  end

  def format_subscription(subscription)
    subscription.is_a?(Travis::Models::Billing::V2Subscription) ? format_v2_subscription(subscription) : format_old_subscription(subscription)
  end

  def format_v2_subscription(subscription)
    if subscription.plan_config[:plan_type] == 'hybrid'
      jobs = pluralize(subscription.concurrency_limit, 'concurrent job')
      "#{subscription.plan_config[:name]} / #{jobs}"
    else
      users = pluralize(subscription.plan_config[:starting_users], 'user')
      credits = pluralize(subscription.plan_config[:private_credits], 'credit')
      "#{subscription.plan_config[:name]} / #{users} / #{credits}"
    end
  end

  def format_old_subscription(subscription)
    if subscription.active?
      "active, #{format_plan(subscription.selected_plan) || 'unknown plan'}, expires #{subscription.valid_to.to_date}"
    elsif subscription.expired?
      "inactive, #{format_plan(subscription.selected_plan) || 'unknown plan'}, expired #{subscription.valid_to.to_date}"
    else
      'not active'
    end
  end
end
