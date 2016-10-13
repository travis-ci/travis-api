class SubscriptionsController < ApplicationController
  include Presenters
  
  before_action :get_subscription

  def show
  end

  def update
    @subscription.attributes = subscription_params
    changes = @subscription.changes

    if changes.any? && @subscription.save
      message = "updated #{@subscription.owner.login}'s subscription: #{changes.map {|attr, change| "#{attr} changed from #{change.first} to #{change.last}"}.join(", ")}".gsub(/ \d{2}:\d{2}:\d{2} UTC/, "")
      flash[:notice] = message.sub(/./) {$&.upcase}
      Services::AuditTrail::UpdateSubscription.new(current_user, message).call
      redirect_to @subscription
    else
      render :show
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:valid_to, :billing_email, :vat_id)
  end

  def get_subscription
    subscription = Subscription.find_by(id: params[:id])
    return redirect_to root_path, alert: 'There is no subscription associated with that ID.' if subscription.nil?
    @subscription = present(subscription)
  end
end
