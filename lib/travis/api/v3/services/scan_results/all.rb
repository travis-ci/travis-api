module Travis::API::V3
  class Services::ScanResults::All < Service
    params :repository_id
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      repository = Travis::API::V3::Models::Repository.find(params['repository_id'])
      check_access(repository)

      result query(:scan_results).all
    end

    def check_access(repository)
      access_control.permissions(repository).check_scan_results!
    end
  end
end
