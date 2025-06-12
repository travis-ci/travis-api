module Travis::API::V3
  class Renderer::Membership < ModelRenderer
    representation(:minimal, :organization_id, :build_permission)
    representation(:standard, :user_id, :organization_id, :role, :build_permission)
  end
end
