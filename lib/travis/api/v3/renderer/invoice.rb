module Travis::API::V3
  class Renderer::Invoice < ModelRenderer
    representation(:standard, :id, :created_at, :status, :url, :amount_due)
  end
end
