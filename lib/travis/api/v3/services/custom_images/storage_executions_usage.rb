module Travis::API::V3
  class Services::CustomImages::StorageExecutionsUsage < Service
    result_type :storage_executions_usages

    def run!
      raise MethodNotAllowed if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      result query(:custom_images).storage_executions_usage(owner, access_control.user.id)
    end
  end
end
