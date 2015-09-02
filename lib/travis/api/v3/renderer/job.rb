require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Job < Renderer::ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner )
  end
end
