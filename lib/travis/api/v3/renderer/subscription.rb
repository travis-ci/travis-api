module Travis::API::V3
  class Renderer::Subscription < ModelRenderer
    representation(:standard, :id, :valid_to, :plan, :coupon, :status, :source, :billing_info, :credit_card_info, :owner)
  end
end
