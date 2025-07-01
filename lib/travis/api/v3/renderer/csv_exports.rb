module Travis::API::V3
  class Renderer::CsvExports < ModelRenderer
    representation(:minimal, :status, :message, :owner_id, :owner_type)
    representation(:standard, :status, :message, :owner_id, :owner_type)
  end
end
