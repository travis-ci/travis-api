module Travis::API::V3
  class Renderer::V2PlanConfig < ModelRenderer
    representation(:standard, :id, :name, :private_repos, :price, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type, :available_standalone_addons)
    representation(:minimal, :id, :name, :private_repos, :price, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type)
  end
end
