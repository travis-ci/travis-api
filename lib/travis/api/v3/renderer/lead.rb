module Travis::API::V3
  class Renderer::Lead < ModelRenderer
    representation(:standard, :id, :name, :phones)
  end
end
