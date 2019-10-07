module Travis::API::V3
  class Renderer::Coupon < ModelRenderer
    representation(:minimal,  :id, :name, :percent_off, :amount_off, :value)
    representation(:standard, *representations[:minimal])
  end
end
