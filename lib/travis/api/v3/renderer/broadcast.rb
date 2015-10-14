require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Broadcast < Renderer::ModelRenderer
    representation(:minimal,  :id, :message, :created_at, :category, :active)
    representation(:standard, :id,  *representations[:minimal], :recipient)

    def active
      model.active?
    end
  end
end
