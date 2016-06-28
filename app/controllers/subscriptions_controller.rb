class SubscriptionsController < ApplicationController
  def show
    @subscription = Subscription.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no subscription associated with that ID." if @subscription.nil?

    @plan = @subscription.plans.last
    @invoices = @subscription.invoices.order('id DESC')
  end
end
