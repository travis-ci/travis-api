module Travis::API::V3
  class Renderer::InsightsTag < ModelRenderer
    representation :standard, :name
    representation :minimal, :name
  end
end
