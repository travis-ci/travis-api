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
    @subscription.active? ? "#{h.format_plan(@plan.name)} (#{h.format_price(plan_amount)})" : 'No Plan.'
  end

  private

  def plan_amount
    @plan.try(:amount) ? @plan.amount : 0
  end
end