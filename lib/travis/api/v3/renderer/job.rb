require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Job < Renderer::ModelRenderer
    representation(:minimal, :id, :number, :state, :started_at, :finished_at)
    representation(:standard, *representations[:minimal], :build, :queue, :repository, :commit, :owner )
  end
end
