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

  def v2_create
    owner_id = params[:subscription][:owner_id]
    owner_type = params[:subscription][:owner_type]
    permitted_params = v2_create_subscription_params
    if owner_type == 'Organization'
      permitted_params[:organization_id] = owner_id
    end

    permitted_params[:billing_info] = {
      first_name: '',
      last_name: '',
      address: '',
      city: '',
      country: '',
      zip_code: '',
      billing_email: ''
    }
    permitted_params[:credit_card_info] = { token: '' }
    permitted_params[:source] = permitted_params[:plan] == 'free_tier_plan' ? 'stripe' : 'manual'

    error_message = Services::Billing::V2Subscription.new(owner_id, owner_type).create_subscription(permitted_params)
    if error_message.blank?
      flash[:notice] = 'Subscription successfully created'
    else
      flash[:error] = "Subscription create failed: #{error_message.inspect}"
    end

    redirect_to controller: params[:subscription][:owner_type].downcase.pluralize, action: 'subscription', id: params[:subscription][:owner_id]
  end

  def v2_update
    url = params[:owner_type] == 'User' ? subscription_user_path(params[:owner_id]) : subscription_organization_path(params[:owner_id])

    if params[:subscription].blank? || params[:subscription][:change_reason].blank?
      flash[:error] = 'Change reason cannot be blank.'
      redirect_to url
      return
    end

    if params.key?(:auto_refill) && !params[:auto_refill][:id].blank?
      error_message = Services::Billing::V2Subscription.new(params[:owner_id], params[:owner_type]).update_auto_refill(params[:id], { id: params[:auto_refill][:id], threshold: params[:auto_refill][:threshold], amount: params[:auto_refill][:amount], change_reason: params[:subscription][:change_reason] })
    end
    if params.key?(:create_addon) && !params[:new_addon][:id].blank?
      error_message = Services::Billing::V2Subscription.new(params[:owner_id], params[:owner_type]).create_addon(params[:id], { addon: params[:new_addon][:id], user_id: current_user.id, change_reason: params[:subscription][:change_reason] })
    elsif params.key?(:create_free_user_license)
      error_message = Services::Billing::V2Subscription.new(params[:owner_id], params[:owner_type]).create_addon(params[:id], { addon: 'users_free_for_paid_plans', user_id: current_user.id, change_reason: params[:subscription][:change_reason] })
    else
      permitted_params = v2_subscription_params
      permitted_params.delete(:valid_to) if permitted_params[:source] != 'manual'
      permitted_params[:plan_name] = params[:subscription][:plan_name] if params[:subscription][:plan_name] != params[:old_plan_name]
      if permitted_params[:addons].present? && !permitted_params[:plan_name]
        new_addons = permitted_params[:addons].permit!.to_h.each_with_object([]) do |(addon_id, addon_data), memo|
          addon_data.delete(:valid_to) if permitted_params[:source] != 'manual'
          memo << addon_data.merge(id: addon_id)
        end
        permitted_params[:addons] = new_addons
      else
        permitted_params.delete(:addons)
      end
      permitted_params[:user_id] = current_user.id
      if params[:subscription].key?(:auto_refill)
        permitted_params[:auto_refill] = params[:subscription][:auto_refill].permit!.to_h
      end
      error_message = Services::Billing::V2Subscription.new(params[:owner_id], params[:owner_type]).update_subscription(params[:id], permitted_params)
    end

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

  def v2_create_subscription_params
    params.require(:subscription).permit(:plan)
  end

  def v2_subscription_params
    params.require(:subscription).permit(:change_reason, :source, :status, :valid_to, :billing_email, :vat_id, :zip_code, :address, :address2, :city, :state, :country, :concurrency_limit, addons: {})
  end
end
