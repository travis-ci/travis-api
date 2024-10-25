module Travis::API::V3
  class Renderer::V2PlanConfig < ModelRenderer
    representation(:standard, :id, :name, :private_repos, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type, :concurrency_limit, :available_standalone_addons, :trial_plan, :annual, :auto_refill_thresholds, :auto_refill_amounts, :trial_config, :vm_size)
    representation(:minimal, :id, :name, :private_repos, :starting_price, :starting_users, :private_credits,
                   :public_credits, :addon_configs, :plan_type, :concurrency_limit, :trial_plan, :annual, :auto_refill_thresholds, :auto_refill_amounts, :trial_config, :vm_size)
  end
end
