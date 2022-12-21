module Travis::API::V3
  class Services::ScanResult::Find < Service
    params :id

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      scan_result = query(:scan_result).find
      
      repository = Travis::API::V3::Models::Repository.find(scan_result.repository_id)
      check_access(repository)

      result scan_result
    end

    def check_access(repository)
      access_control.permissions(repository).check_scan_results!
    end
  end
end
