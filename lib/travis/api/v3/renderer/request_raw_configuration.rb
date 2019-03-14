module Travis::API::V3
  class Renderer::RequestRawConfiguration < ModelRenderer
    representation(:minimal, :config, :source)
    representation(:standard, *representations[:minimal])

    def config
      model.raw_config&.config
    end
  end
end
