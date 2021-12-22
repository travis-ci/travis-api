module Travis::API::V3
  module Renderer::ArtifactsImageBuildStatus
    extend self

    AVAILABLE_ATTRIBUTES = [:name, :status]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'artifacts_image_build_status'.freeze,
        name: object['name'],
        status: object['status']
      }
    end
  end
end