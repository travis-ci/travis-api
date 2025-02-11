module Travis::API::V3
  class Renderer::BulkChangeResult < ModelRenderer
    representation(:standard, :changed,:skipped)
  end
end
