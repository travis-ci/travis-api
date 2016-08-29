class SubscriptionsController < ApplicationController
  def show
    @subscription = Subscription.find_by(id: params[:id])
    return redirect_to root_path, alert: 'There is no subscription associated with that ID.' if @subscription.nil?

    @plan = @subscription.plans.current
    @invoices = @subscription.invoices.order('id DESC')
  end

  def update
    @subscription = Subscription.find_by(id: params[:id])

    if @subscription.update(subscription_params)
      flash[:notice] = "Updated #{@subscription.owner.login}'s subscription."
    else
      flash[:error] = "Unable to save changes."
    end

    redirect_to @subscription
  end

  private
    def subscription_params
      params.require(:subscription).permit(:valid_to, :billing_email, :vat_id)
    end
end
