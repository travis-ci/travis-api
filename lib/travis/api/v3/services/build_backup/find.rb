module Travis::API::V3
  class Services::BuildBackup::Find < Service
    params :repository_id

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:build_backup).find
    end
  end
end
