module Travis::API::V3
  class Renderer::LogParts < ModelRenderer
    representation(:standard, :log_parts)

    def log_parts
      @model.log_parts
    end
  end
end
