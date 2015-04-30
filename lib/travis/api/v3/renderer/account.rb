require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Account < Renderer::ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :subscribed, :educational, :owner)
  end
end
