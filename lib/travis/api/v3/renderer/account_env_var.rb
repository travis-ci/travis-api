module Travis::API::V3
  class Renderer::AccountEnvVar < ModelRenderer
    representation :standard, :id, :owner_id, :owner_type, :name, :value, :public, :created_at, :updated_at
    representation :minimal, *representations[:standard]

  end
end
