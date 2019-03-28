module Travis::API::V3
  class Renderer::Proxy < ModelRenderer
    representation(:standard, :data)

    alias_method :data, :model
  end
end
