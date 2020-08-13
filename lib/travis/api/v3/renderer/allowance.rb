module Travis::API::V3
  class Renderer::Allowance < ModelRenderer
    representation(:minimal, :public_repos, :private_repos, :concurrency_limit)
  end
end
