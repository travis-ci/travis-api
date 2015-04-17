require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::User < Renderer::Account
    representation(:standard, :is_syncing, :synced_at)
  end
end
