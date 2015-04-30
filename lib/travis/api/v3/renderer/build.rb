require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Build < Renderer::ModelRenderer
    representation(:minimal,  :id, :number, :state, :duration, :event_type, :previous_state, :started_at, :finished_at)
    representation(:standard, *representations[:minimal], :repository, :branch)
  end
end
