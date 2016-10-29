class SubscriptionPresenter < SimpleDelegator
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
    @subscription.active? ? "#{h.format_plan(@plan.name)} (#{h.format_price(@plan.amount)})" : 'No Plan.'
  end
end