module Travis::API::V3
  class Services::CustomKey::Delete < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      query(:custom_key).delete(params, access_control.user)
      deleted
    end
  end
end
