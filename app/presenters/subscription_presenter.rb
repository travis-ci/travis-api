class SubscriptionPresenter < SimpleDelegator
  def initialize(subscription, view)
    @subscription = subscription
    @view = view
    super(@subscription)
  end

  def h
    @view
  end

  def coupon
   @subscription.coupon ? @subscription.coupon : 'No Coupon.'
  end

  def invoices
    @invoices ||= @subscription.invoices.order('id DESC')
  end

  def plan
    @plan ||= @subscription.plans.current
  end

  def plan_title
    if @plan.present?
      "#{@plan.name} (#{h.format_price(@plan.amount)}/month)"
    else
      'No Plan.'
    end
  end
end