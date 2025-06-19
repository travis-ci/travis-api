module Travis::API::V3
  class Renderer::CsvExports < ModelRenderer
    representation(:minimal, :status, :message, :owner_id)
    representation(:standard, :status, :message, :owner_id)
  end
end
