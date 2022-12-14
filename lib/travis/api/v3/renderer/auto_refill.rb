module Travis::API::V3
  class Renderer::AutoRefill < ModelRenderer
    representation(:standard, :addon_id, :enabled, :threshold, :amount)
    representation(:minimal, :addon_id, :enabled, :threshold, :amount)
  end
end
