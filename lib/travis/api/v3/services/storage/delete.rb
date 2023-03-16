module Travis::API::V3
  class Services::Storage::Delete < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      params['user.id'] = access_control.user&.id
      result query.delete
    end
  end
end
