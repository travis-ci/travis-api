module Travis::API::V3
  class Renderer::CreditsResult < ModelRenderer
    representation(:standard, :users, :minutes, :os, :instance_size, :credits, :price)
  end
end
