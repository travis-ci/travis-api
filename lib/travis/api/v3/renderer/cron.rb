require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Cron < Renderer::ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :branch, :repository)

    def repository
      model.branch.repository
    end

  end
end
