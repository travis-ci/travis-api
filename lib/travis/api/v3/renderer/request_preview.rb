module Travis::API::V3
  class Renderer::RequestPreview < ModelRenderer
    representation(:minimal, :raw_configs, :request_config, :job_configs, :messages, :full_messages)
    representation(:standard, *representations[:minimal])
  end
end
