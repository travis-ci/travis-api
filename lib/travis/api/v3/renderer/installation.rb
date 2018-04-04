module Travis::API::V3
  class Renderer::Installation < ModelRenderer
    representation(:minimal,  :id, :github_installation_id)
    representation(:standard, *representations[:minimal], :owner_type, :owner_id)
  end
end