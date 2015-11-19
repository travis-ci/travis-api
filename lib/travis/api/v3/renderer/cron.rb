require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Cron < Renderer::ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :repository, :branch, :hour, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :disable_by_push)

    def repository
      model.branch.repository
    end

  end
end
