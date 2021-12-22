module Travis::API::V3
  module Renderer::ArtifactsImageLogs
    extend self

    AVAILABLE_ATTRIBUTES = [:name, :log]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'artifacts_image_logs'.freeze,
        name: object['name'],
        log: object['log']
      }
    end
  end
end