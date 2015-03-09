require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::User < Renderer::ModelRenderer
    representation(:minimal,  :id, :login)
    representation(:standard, :id, :login, :name, :github_id, :is_syncing, :synced_at)
  end
end
