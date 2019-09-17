module Travis::API::V3
  class Renderer::Lead < ModelRenderer
    representation(:standard, :id, :name, :status_label, :contacts, :custom)
  end
end
