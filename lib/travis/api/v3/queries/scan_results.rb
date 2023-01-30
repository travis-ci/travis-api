module Travis::API::V3
  class Queries::ScanResults < Query
    params :repository_id, :offset, :limit

    def all
      # Reset the scan status on viewing the reports
      Repository.find(repository_id).update!(scan_failed_at: nil)

      page = (offset.to_i / limit.to_i) + 1
      scanner_client(repository_id).scan_results(
        page.to_s,
        limit
      )
    end

    private

    def scanner_client(repository_id)
      @_scanner_client ||= ScannerClient.new(repository_id)
    end
  end
end
