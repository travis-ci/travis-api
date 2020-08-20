module Travis::API::V3
  class Renderer::V2PlanConfig < ModelRenderer
    representation(:standard, :id, :name, :private_repos, :default_addons, :starting_price, :starting_users)
    representation(:minimal, :id, :name, :private_repos, :default_addons, :starting_price, :starting_users)
  end
end
