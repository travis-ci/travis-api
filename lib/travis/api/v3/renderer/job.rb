require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Jobs < Renderer::ModelRenderer
    representation(:minimal,  :id, :number, :state, :duration, :started_at, :finished_at, :allow_failure, :queue)
    representation(:standard, *representations[:minimal], :repository, :build, :commit)

    def queue
      {
        :@type => 'queue'.freeze,
        :name  => model.queue
      }
    end
  end
end
