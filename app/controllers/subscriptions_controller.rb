class SubscriptionsController < ApplicationController

  def create
    @subscription = Subscription.new(subscription_params)
    @subscription.cc_token      = "void"
    @subscription.valid_to      = 1.year.from_now
    @subscription.billing_email = "support@travis-ci.com"

    if @subscription.save
      flash[:notice] = "Created a new subscription for #{describe(@subscription.owner)}"
      Services::AuditTrail::CreateSubscription.new(current_user, @subscription).call
    else
      flash[:error]  = 'Could not create subscription.'
    end
    redirect_to @subscription.owner
  end

  def update
    @subscription = Subscription.find_by(id: params[:id])
    @subscription.attributes = subscription_params

    changes = @subscription.changes

    if changes.any? && @subscription.save
      message = "updated #{@subscription.owner.login}'s subscription: #{changes.map {|attr, change| "#{attr} changed from #{change.first} to #{change.last}"}.join(", ")}".gsub(/ \d{2}:\d{2}:\d{2} UTC/, "")
      flash[:notice] = message.sub(/./) {$&.upcase}
      Services::AuditTrail::UpdateSubscription.new(current_user, message).call
    else
      flash[:error] = 'No subscription changes were made.'
    end

    redirect_to controller: @subscription.owner.class.table_name, action: 'show', id: @subscription.owner, anchor: 'subscription'
  end

  private

  def subscription_params
    params.require(:subscription).permit(:valid_to, :billing_email, :vat_id, :owner_type, :owner_id, :selected_plan)
  end

  # def get_subscription
    # subscription = Subscription.find_by(id: params[:id])
    # return redirect_to root_path, alert: 'There is no subscription associated with that ID.' if subscription.nil?
    # plan = subscription.plans.current
    # @subscription = SubscriptionPresenter.new(subscription, plan, self) unless subscription.nil?
    # @invoices = subscription.invoices.order('id DESC')
  # end
end
