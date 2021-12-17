module Travis::API::V3
  class Queries::ArtifactsImage < Query
    params :image_name

    def logs(user_id)
      artifacts_client(user_id).image_logs(params['image_name'])
    end

    def info(user_id)
      artifacts_client(user_id).image_info(params['image_name'])
    end

    def delete(user_id)
      artifacts_client(user_id).delete_image(params['image_name'])
    end

    def artifacts_client(user_id)
      @_artifacts_client ||= ArtifactsClient.new(user_id)
    end
  end
end
