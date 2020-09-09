module Travis::API::V3
  class Renderer::V2AddonUsage < ModelRenderer
    representation(:standard, :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :active)
    representation(:minimal, :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :active)
  end
end
