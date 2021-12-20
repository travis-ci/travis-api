module Travis::API::V3
  class Renderer::InsightsPublicKey < ModelRenderer
    representation(:standard, :key_hash, :key_body, :ordinal_value)
  end
end
