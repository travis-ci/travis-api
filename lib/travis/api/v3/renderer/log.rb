module Travis::API::V3
  class Renderer::Log < Renderer::ModelRenderer
    representation(:minimal, :id, :content)
    representation(:standard, *representations[:minimal], :log_parts)
  end
end
