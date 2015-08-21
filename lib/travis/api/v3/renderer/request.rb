require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Request < Renderer::ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :repository, :commit, :owner, :created_at, :result, :message, :event_type)
  end
end
