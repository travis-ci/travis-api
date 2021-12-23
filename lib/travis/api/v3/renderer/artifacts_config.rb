module Travis::API::V3
  module Renderer::ArtifactsConfig
    extend self

    AVAILABLE_ATTRIBUTES = [:id, :image_name, :is_valid, :is_pushed, :push_sha, :warnings]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'artifacts_config'.freeze,
        id: object['id'],
        image_name: object['image_name'],
        is_valid: object['is_valid'],
        is_pushed: object['is_pushed'],
        push_sha: object['push_sha'],
        warnings: object['warnings']
      }
    end
  end
end