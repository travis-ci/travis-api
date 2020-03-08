module Travis::API::V3
  class Renderer::RequestConfig < ModelRenderer
    representation(:minimal, :config)
    representation(:standard, *representations[:minimal])
  end
end
