module Travis::API::V3
  class Services::ArtifactsImage::Info < Service
    params :image_name
    result_type :artifacts_image_info

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:artifacts_image).info(access_control.user.id)
    end
  end
end
