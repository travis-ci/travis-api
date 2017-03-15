require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Stage < Renderer::ModelRenderer
    representation(:minimal, :id, :number, :name)
    representation(:standard, *representations[:minimal], :jobs)
    representation(:active, *representations[:standard])
  end
end
