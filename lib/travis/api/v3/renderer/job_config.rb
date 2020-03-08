module Travis::API::V3
  class Renderer::JobConfig < ModelRenderer
    representation(:minimal, :config)
    representation(:standard, *representations[:minimal])
  end
end
