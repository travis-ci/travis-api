module Travis::API::V3
  class Renderer::Coupon < ModelRenderer
    representation(:minimal, :id, :name, :percent_off, :amount_off, :valid)
    representation(:standard, *representations[:minimal])
  end
end
