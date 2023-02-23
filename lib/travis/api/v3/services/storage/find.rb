module Travis::API::V3
  class Services::Storage::Find < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      result query.find
    end
  end
end
