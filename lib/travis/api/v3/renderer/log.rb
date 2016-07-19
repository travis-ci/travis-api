require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Log < Renderer::ModelRenderer
    representation(:standard, :id, :content)
  end
end
