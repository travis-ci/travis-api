module Travis::API::V3
    class Services::ArtifactsImage::BuildStatus < Service
      params :image_name
      result_type :artifacts_image_build_status
  
      def run!
        raise LoginRequired unless access_control.full_access_or_logged_in?
        result query(:artifacts_image).build_status(access_control.user.id)
      end
    end
  end
  