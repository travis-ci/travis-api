require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Job < Renderer::ModelRenderer
    # # representation(:minimal,  :id, :number, :state, :queue, :type, :started_at, :finished_at)
    # representation(:minimal,  :id)
    # # representation(:standard, *representations[:minimal], :repository_id, :commit_id, :source_type, source_id)
    # representation(:standard, *representations[:minimal])
  end
end
