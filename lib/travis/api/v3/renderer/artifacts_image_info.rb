module Travis::API::V3
  module Renderer::ArtifactsImageInfo
    extend self

    AVAILABLE_ATTRIBUTES = [:name, :config_content, :description, :image_size]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'artifacts_image_info'.freeze,
        name: object['name'],
        config_content: object['config_content'],
        description: object['description'],
        image_size: object['image_size']
      }
    end
  end
end