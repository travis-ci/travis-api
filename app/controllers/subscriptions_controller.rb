class SubscriptionsController < ApplicationController
  def show
    @subscription = Subscription.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no subscription associated with that ID." if @subscription.nil?

    @plan = @subscription.plans.current
    @invoices = @subscription.invoices.order('id DESC')
  end

  def update
    @subscription = Subscription.find_by(id: params[:id])

    @subscription.attributes = subscription_params.slice('billing_email', 'vat_id', 'valid_to').reject do |name, value|
      if name == 'valid_to'
        @subscription['valid_to'].strftime("%Y-%m-%d") ==  value
      end
    end

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
