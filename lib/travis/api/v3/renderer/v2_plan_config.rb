module Travis::API::V3
  class Renderer::V2PlanConfig < ModelRenderer
    representation(:standard, :id, :name, :private_repos, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type, :concurrency_limit, :available_standalone_addons)
    representation(:minimal, :id, :name, :private_repos, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type, :concurrency_limit)
  end
end
