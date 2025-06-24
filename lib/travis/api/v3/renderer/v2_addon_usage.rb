module Travis::API::V3
  class Renderer::V2AddonUsage < ModelRenderer
    representation(:standard, :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :purchase_date, :valid_to,
                   :active, :status, :total_usage, :quantity_free_limit, :quantity_limit_type, :quantity_limit_charge)
    representation(:minimal, :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :purchase_date, :valid_to,
                   :active, :status, :total_usage, :quantity_free_limit, :quantity_limit_type, :quantity_limit_charge)
  end
end
