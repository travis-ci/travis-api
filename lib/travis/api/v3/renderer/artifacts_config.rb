module Travis::API::V3
  module Renderer::ArtifactsConfig
    extend self

    AVAILABLE_ATTRIBUTES = [:id, :image_name, :is_valid]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'artifacts_config'.freeze,
        id: object['id'],
        image_name: object['image_name'],
        is_valid: object['is_valid']
      }
    end
  end
end