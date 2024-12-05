module Travis::API::V3
  class Renderer::V2Subscription < ModelRenderer
    representation(:standard, :id, :plan, :addons, :auto_refill, :status, :valid_to, :canceled_at, :source, :owner, :client_secret, :billing_info, :credit_card_info, :payment_intent, :created_at, :scheduled_plan_name, :cancellation_requested, :current_trial, :defer_pause)

    def billing_info
      Renderer.render_model(model.billing_info, mode: :standard) unless model.billing_info.nil?
    end

    def credit_card_info
      Renderer.render_model(model.credit_card_info, mode: :standard) unless model.credit_card_info.nil?
    end

    def plan
      Renderer.render_model(model.plan, mode: :standard) unless model.plan.nil?
    end

    def payment_intent
      Renderer.render_model(model.payment_intent, mode: :standard) unless model.payment_intent.nil?
    end

    def current_trial
      Renderer.render_model(model.current_trial,mode: :standard) unless model.current_trial.nil?
    end
  end

  class Renderer::V2BillingInfo < ModelRenderer
    representation(:standard, :id, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code, :has_local_registration)
  end

  class Renderer::V2CreditCardInfo < ModelRenderer
    representation(:standard, :id, :card_owner, :expiration_date, :last_digits)
  end
end
