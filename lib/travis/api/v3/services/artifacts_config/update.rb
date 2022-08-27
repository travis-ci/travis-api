module Travis::API::V3
  class Services::ArtifactsConfig::Update < Service
    params :config, :image_name

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:artifacts_config).update(access_control.user.id)
    end
  end
end
