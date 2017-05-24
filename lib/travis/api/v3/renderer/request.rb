require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Request < Renderer::ModelRenderer
    representation(:minimal,  :id, :state, :result, :message)
    representation(:standard, *representations[:minimal], :repository, :branch_name, :commit, :owner, :created_at, :event_type)
  end
end
