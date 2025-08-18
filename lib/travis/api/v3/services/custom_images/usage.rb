module Travis::API::V3
  class Services::CustomImages::Usage < Service
    result_type :custom_images_usages
    params :from, :to

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      result query(:custom_images).usage(owner, access_control.user.id, params['from'], params['to'])
    end
  end
end
