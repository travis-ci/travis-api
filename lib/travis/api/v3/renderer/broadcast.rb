module Travis::API::V3
  class Renderer::Broadcast < ModelRenderer
    representation(:minimal,  :id, :message, :created_at, :category, :active)
    representation(:standard, :id,  *representations[:minimal], :recipient)

    def active
      model.active?
    end
  end
end
