require 'travis/api/v3/renderer/model_renderer'
require 'travis/api/v3/renderer/avatar_url'

module Travis::API::V3
  class Renderer::Owner < Renderer::ModelRenderer
    include Renderer::AvatarURL

    representation(:minimal,  :id, :login)
    representation(:standard, :id, :login, :name, :github_id, :avatar_url)
  end
end
