describe Travis::API::V3::ScannerClient, scanner_spec_helper: true do
  let(:scanner_client) { described_class.new(repository_id.to_s) }
  let(:repository_id) { rand(999) }
  let(:scanner_url) { 'https://scanner' }
  let(:auth_key) { 'supersecret' }

  before do
    Travis.config.scanner.url = scanner_url
    Travis.config.scanner.token = auth_key
  end

  describe '#scan_results' do
    let(:page) { '1' }
    let(:limit) { '25' }

    subject { scanner_client.scan_results(page, limit) }

    it 'requests user notifications with specified query' do
      stub_scanner_request(:get, '/scan_results', query: "repository_id=#{repository_id}&page=#{page}&limit=#{limit}", auth_key: auth_key)
        .to_return(body: JSON.dump(scanner_scan_results_response(1)))
      expect(subject).to be_a(Travis::API::V3::Models::ScannerCollection)
      expect(subject.map { |e| e }.first).to be_a(Travis::API::V3::Models::ScanResult)
      expect(subject.map { |e| e }.size).to eq(scanner_scan_results_response(1)['scan_results'].size)
      expect(subject.count).to eq(scanner_scan_results_response(1)['total_count'])
    end
  end

  describe '#get_scan_result' do
    let(:scan_result_id) { rand(999) }

    subject { scanner_client.get_scan_result(scan_result_id) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 201, body: JSON.dump(scanner_scan_result_response(1, 1)))

      expect(subject).to be_a(Travis::API::V3::Models::ScanResult)
      expect(subject.issues_found).to eq(1)
      expect(stubbed_request).to have_been_made
    end
  end

  describe 'error handling' do
    let(:scan_result_id) { rand(999) }

    subject { scanner_client.get_scan_result(scan_result_id) }

    it 'returns true when 202' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 202)

      expect(subject).to be_truthy
      expect(stubbed_request).to have_been_made
    end

    it 'returns true when 204' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 204)

      expect(subject).to be_truthy
      expect(stubbed_request).to have_been_made
    end

    it 'raises error when 400' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 400, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::ClientError)
    end

    it 'raises error when 403' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 403, body: JSON.dump({rejection_code: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::InsufficientAccess)
    end

    it 'raises error when 404' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 404, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::NotFound)
    end

    it 'raises error when 422' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 422, body: JSON.dump({error: 'error text'}))

      expect { subject }.to raise_error(Travis::API::V3::UnprocessableEntity)
    end

    it 'raises error when 500' do
      stubbed_request = stub_scanner_request(:get, "/scan_results/#{scan_result_id}", auth_key: auth_key)
        .to_return(status: 500)

      expect { subject }.to raise_error(Travis::API::V3::ServerError)
    end
  end
end
