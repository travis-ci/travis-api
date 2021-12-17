module Travis::API::V3
  class Services::ArtifactsImage::Logs < Service
    params :image_name

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:artifacts_image).logs(access_control.user.id)
    end
  end
end
