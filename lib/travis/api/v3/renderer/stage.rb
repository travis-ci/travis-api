require 'travis/api/v3/model_renderer'

module Travis::API::V3
  class Renderer::Stage < ModelRenderer
    representation(:minimal, :id, :number, :name)
    representation(:standard, *representations[:minimal], :jobs)
    representation(:active, *representations[:standard])
  end
end
