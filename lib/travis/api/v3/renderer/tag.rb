module Travis::API::V3
  class Renderer::Tag < ModelRenderer
    representation(:minimal, :repository_id, :name, :last_build_id)
    representation(:standard, :repository_id, :name, :last_build_id)
  end
end
