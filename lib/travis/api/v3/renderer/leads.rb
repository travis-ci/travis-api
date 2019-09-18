module Travis::API::V3
  class Renderer::Leads < ModelRenderer
    representation(:standard, :id, :name, :status_label, :contacts, :custom)
  end
end
