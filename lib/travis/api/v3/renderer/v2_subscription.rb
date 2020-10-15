module Travis::API::V3
  class Renderer::V2Subscription < ModelRenderer
    representation(:standard, :id, :plan, :addons, :status, :valid_to, :canceled_at, :source, :owner, :client_secret, :billing_info, :credit_card_info, :payment_intent, :created_at)

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
  end

  class Renderer::V2BillingInfo < ModelRenderer
    representation(:standard, :id, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code)
  end

  class Renderer::V2CreditCardInfo < ModelRenderer
    representation(:standard, :id, :card_owner, :expiration_date, :last_digits)
  end
end
