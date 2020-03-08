module Travis::API::V3
  class Renderer::Message < ModelRenderer
    representation(:minimal, :id, :level, :key, :code, :args, :src, :line)
    representation(:standard, *representations[:minimal])
  end
end
