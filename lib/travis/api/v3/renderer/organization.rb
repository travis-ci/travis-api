require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Organization < Renderer::ModelRenderer
    representation(:minimal,  :id, :login)
    representation(:standard, :id, :login, :name, :github_id)
  end
end
