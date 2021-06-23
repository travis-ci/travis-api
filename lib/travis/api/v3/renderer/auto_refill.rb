module Travis::API::V3
  class Renderer::AutoRefill < ModelRenderer
    representation(:standard, :enabled, :threshold, :amount)
    representation(:minimal, :enabled, :threshold, :amount)
  end
end
