module Travis::API::V3
  class Services::BuildBackups::All < Service
    params :repository_id
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:build_backups).all
    end
  end
end
