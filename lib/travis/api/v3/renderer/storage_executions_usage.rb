module Travis::API::V3
  class Renderer::StorageExecutionsUsage < ModelRenderer
    representation :minimal, :estimated_usage
    representation :standard, *representations[:minimal]
  end
end
