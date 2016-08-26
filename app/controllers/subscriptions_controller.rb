class SubscriptionsController < ApplicationController
  def show
    @subscription = Subscription.find_by(id: params[:id])
    return redirect_to root_path, alert: 'There is no subscription associated with that ID.' if @subscription.nil?

    @plan = @subscription.plans.current
    @invoices = @subscription.invoices.order('id DESC')
  end

  def update
    @subscription = Subscription.find_by(id: params[:id])
    @subscription.attributes = subscription_params.slice('billing_email', 'vat_id', 'valid_to(1i)', 'valid_to(2i)', 'valid_to(3i)').reject
    changes = @subscription.changes
    @subscription.save

    flash[:notice] = "Updated #{@subscription.owner.login}'s subscription: #{changes.map {|attr, change| "#{attr} changed from #{change.first.inspect} to #{change.last.inspect}"}.join(", ")}"
    redirect_to @subscription
  end

  private
    def subscription_params
      params.require(:subscription).permit(:valid_to, :billing_email, :vat_id)
    end
end
