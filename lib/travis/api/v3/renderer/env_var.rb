module Travis::API::V3
  class Renderer::EnvVar < Renderer::ModelRenderer
    representation :standard, :id, :name, :value, :public
  end
end
