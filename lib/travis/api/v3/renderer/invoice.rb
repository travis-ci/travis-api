module Travis::API::V3
  class Renderer::Invoice < ModelRenderer
    representation(:standard, :id, :created_at, :url)
  end
end
