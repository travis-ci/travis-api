module Travis::API::V3
  class Renderer::Subscription < ModelRenderer
    representation(:standard, :id, :valid_to, :plan, :coupon, :status, :source, :billing_info, :credit_card_info, :owner)
  end

  class Renderer::BillingInfo < ModelRenderer
    representation(:minimal, :address, :address2, :billing_email, :city, :company, :country, :first_name, :last_name, :state, :vat_id, :zip_code)
  end

  class Renderer::CreditCardInfo < ModelRenderer
    representation(:minimal, :card_owner, :expiration_date, :last_digits)
  end
end
