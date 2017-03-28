module Travis::API::V3
  class Renderer::LogPart < ModelRenderer
    representation(:minimal, :content, :number)
    representation(:standard, *representations[:minimal], :log)
  end
end
