require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::User < Renderer::ModelRenderer
    include Renderer::AvatarURL

    representation(:minimal,  :id, :login)
    representation(:standard, :id, :login, :name, :github_id, :avatar_url, :is_syncing, :synced_at)
  end
end
