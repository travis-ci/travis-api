module Travis::API::V3
  class Services::CustomImages::CurrentStorage < Service
    result_type :custom_image_storage
    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      result query(:custom_images).current_storage(owner, access_control.user.id)
    end
  end
end
