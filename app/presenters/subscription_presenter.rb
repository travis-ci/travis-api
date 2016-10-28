class SubscriptionPresenter < SimpleDelegator
  include SubscriptionsHelper

  def initialize(subscription, plan, view)
    @subscription = subscription
    @plan = plan
    @view = view
    super(@subscription)
  end

  def h
    @view.view_context
  end

  def coupon
   @subscription.coupon ? @subscription.coupon : 'No Coupon.'
  end

  def expiration_status
    @subscription.active? ? 'Expires:' : 'Expired:'
  end

  def plan_title
    if @plan.present?
      "#{h.format_plan(@plan.name)} (#{h.format_price(@plan.amount)})"
      # (#{format_price(@plan.amount)}/month)"
    else
      'No Plan.'
    end
  end
end