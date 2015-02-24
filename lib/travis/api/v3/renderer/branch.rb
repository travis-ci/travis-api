require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Branch < Renderer::ModelRenderer
    representation(:minimal,  :name, :last_build)
    representation(:standard, :name, :repository, :last_build)
  end
end
