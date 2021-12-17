module Travis::API::V3
  class Services::ArtifactsImage::Delete < Service
    params :image_name

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query(:artifacts_image).delete(access_control.user.id) and deleted
    end
  end
end
