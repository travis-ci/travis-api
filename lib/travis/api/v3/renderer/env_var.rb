module Travis::API::V3
  class Renderer::EnvVar < ModelRenderer
    representation :standard, :id, :name, :value, :public, :branch
    representation :minimal, :id, :name, :public, :branch
  end
end
