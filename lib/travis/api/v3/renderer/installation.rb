module Travis::API::V3
  class Renderer::Installation < ModelRenderer
    representation(:minimal,  :id, :github_id)
    representation(:standard, *representations[:minimal], :owner)
  end
end
