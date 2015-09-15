require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Broadcast < Renderer::ModelRenderer
    representation(:minimal,  :id, :recipient_id, :message, :created_at)
    representation(:standard, :id, :recipient_id, :recipient_type, :kind, :message, :expired, :created_at, :updated_at)
  end
end
