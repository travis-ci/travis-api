class SubscriptionsController < ApplicationController
  include ApplicationHelper

  def create
    @subscription = Subscription.new(subscription_params)
    @subscription.cc_token      = "void"
    @subscription.valid_to      = 1.year.from_now
    @subscription.billing_email = "support@travis-ci.com"
    @subscription.status        = 'subscribed'
    @subscription.source        = 'manual'
    @subscription.concurrency   = travis_config.plans[@subscription.selected_plan.to_sym][:builds]

    if @subscription.save
      flash[:notice] = "Created a new subscription for #{describe(@subscription.owner)}"
      Services::AuditTrail::CreateSubscription.new(current_user, @subscription).call
    else
      flash[:error] = 'Could not create subscription.'
    end
    redirect_to @subscription.owner
  end

  def update
    @subscription = Subscription.find_by(id: params[:id])
    @subscription.attributes = subscription_params

    changes = @subscription.changes

    if @subscription.valid?
      if changes.any?

        begin
          Services::BillingUpdate.new(@subscription, subscription_params).call
          message = "updated #{@subscription.owner.login}'s subscription: #{changes.map {|attr, change| "#{attr} changed from #{change.first} to #{change.last}"}.join(", ")}".gsub(/ \d{2}:\d{2}:\d{2} UTC/, "")
          flash[:notice] = message.sub(/./) {$&.upcase}
        rescue => e
          flash[:error] = "#{e}"
        end

        Services::AuditTrail::UpdateSubscription.new(current_user, message).call
      else
        flash[:error] = 'No subscription changes were made.'
      end
    else
      flash[:error] = @subscription.errors.full_messages[0]
    end

    redirect_to controller: @subscription.owner.class.table_name, action: 'subscription', id: @subscription.owner
  end

  def v2_update
    url = params[:owner_type] == 'User' ? subscription_user_path(params[:owner_id]) : subscription_organization_path(params[:owner_id])

    if params[:subscription].blank? || params[:subscription][:change_reason].blank?
      flash[:error] = 'Change reason cannot be blank.'
      redirect_to url
      return
    end

    permitted_params = v2_subscription_params
    if permitted_params[:addons].present?
      new_addons = permitted_params[:addons].permit!.to_h.each_with_object([]) do |(addon_id, addon_data), memo|
        memo << addon_data.merge(id: addon_id)
      end
      permitted_params[:addons] = new_addons
    end
    permitted_params[:user_id] = current_user.id

    error_message = Services::Billing::V2Subscription.new(params[:owner_id], params[:owner_type]).update_subscription(params[:id], permitted_params)
    if error_message.blank?
      flash[:notice] = 'Subscription successfully updated'
    else
      flash[:error] = "Subscription update failed: #{error_message.inspect}"
    end

    redirect_to url
  end

  private

  def subscription_params
    params.require(:subscription).permit(:valid_to, :billing_email, :vat_id, :owner_type, :owner_id, :selected_plan)
  end

  def v2_subscription_params
    params.require(:subscription).permit(:change_reason, :source, :billing_email, :vat_id, :zip_code, :address, :address2, :city, :state, :country, :concurrency_limit, addons: {})
  end
end
