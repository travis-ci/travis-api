require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Cron < Renderer::ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :repository, :branch, :interval, :disable_by_build, :next_build_time)

    def repository
      model.branch.repository
    end

  end
end
