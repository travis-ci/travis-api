module Travis::API::V3
  class Renderer::Subscription < ModelRenderer
    representation(:standard, :id, :valid_to, :plan, :coupon, :status, :source, :owner, :billing_info, :credit_card_info)

    def billing_info
      Renderer.render_model(model.billing_info, mode: :standard)
    end

    def credit_card_info
      Renderer.render_model(model.credit_card_info, mode: :standard)
    end

    def plan
      Renderer.render_model(model.plan, mode: :standard) unless model.plan.nil?
    end
  end

  class Renderer::BillingInfo < ModelRenderer
    representation(:standard, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code)
  end

  class Renderer::CreditCardInfo < ModelRenderer
    representation(:standard, :card_owner, :expiration_date, :last_digits)
  end
end
