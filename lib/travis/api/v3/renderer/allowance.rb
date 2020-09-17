module Travis::API::V3
  class Renderer::Allowance < ModelRenderer
    representation(:minimal, :subscription_type, :public_repos, :private_repos, :concurrency_limit, :id)
    representation(:standard, :subscription_type, :public_repos, :private_repos, :concurrency_limit, :id)
  end
end
