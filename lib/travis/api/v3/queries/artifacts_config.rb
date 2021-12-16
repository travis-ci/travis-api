module Travis::API::V3
  class Queries::ArtifactsConfig < Query
    params :config, :image_name

    def create(user_id)
      artifacts_client(user_id).create_config(params['config'], params['image_name'])
    end

    def update(user_id)
      artifacts_client(user_id).update_config(params['config'], params['image_name'])
    end

    def artifacts_client(user_id)
      @_artifacts_client ||= ArtifactsClient.new(user_id)
    end
  end
end
