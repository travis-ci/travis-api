module Travis::API::V3
  class Renderer::BetaMigrationRequest < ModelRenderer
    representation(:standard, :id, :owner_id, :owner_name, :owner_type, :accepted_at)
  end
end
