module Travis::API::V3
  class Renderer::JobsStats < ModelRenderer
    representation(:standard, :started, :queued, :queue_name)
  end
end
