module Travis::API::V3
  class Renderer::Trial < ModelRenderer
    representation(:standard, :id, :created_at, :status, :builds_remaining)
  end
end
