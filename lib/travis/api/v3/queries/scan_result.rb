module Travis::API::V3
  class Queries::ScanResult < RemoteQuery
    params :id

    def find
      scanner_client.get_scan_result(id)
    end

    private

    def scanner_client
      @_scanner_client ||= ScannerClient.new(nil)
    end
  end
end
