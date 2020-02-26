class SubscriptionsController < ApplicationController
  include ApplicationHelper

  def create
    @subscription = Subscription.new(subscription_params)
    @subscription.cc_token      = "void"
    @subscription.valid_to      = 1.year.from_now
    @subscription.billing_email = "support@travis-ci.com"
    @subscription.status        = 'subscribed'

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

		if @subscription.valid?
			if changes.any? && @subscription.save
				message = "updated #{@subscription.owner.login}'s subscription: #{changes.map {|attr, change| "#{attr} changed from #{change.first} to #{change.last}"}.join(", ")}".gsub(/ \d{2}:\d{2}:\d{2} UTC/, "")
				flash[:notice] = message.sub(/./) {$&.upcase}

				tax_id = @subscription.vat_required? ? [tax_id(@subscription.country)] : ''
				options = { default_tax_rates: tax_id }
				stripe_subscription = stripe_service.fetch_customer(@subscription).subscription
				stripe_service.update_subscription(stripe_subscription.id, options)

				Services::AuditTrail::UpdateSubscription.new(current_user, message).call
			else
				flash[:error] = 'No subscription changes were made.'
			end
		else
			flash[:error] = @subscription.errors.full_messages[0]
		end

		redirect_to controller: @subscription.owner.class.table_name, action: 'subscription', id: @subscription.owner
	end

  private

  def subscription_params
    params.require(:subscription).permit(:valid_to, :billing_email, :vat_id, :owner_type, :owner_id, :selected_plan)
	end

	def stripe_service
		Services::Stripe.new
	end

	def tax_id(country)
		tax_rates.select { |tax| tax.jurisdiction == country }&.first&.id
	end

	def tax_rates
		stripe_service.tax_rates
	end
end
