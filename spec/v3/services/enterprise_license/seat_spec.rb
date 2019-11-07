describe Travis::API::V3::Services::EnterpriseLicense::Seat, set_app: true do
  let(:license_url) { "https://fake.fakeserver.com:9880/license/v1/license" }
  let(:log)         { stdout.string }

  before do
    Travis.config.enterprise = true
    replicated_endpoint = 'https://fake.fakeserver.com:9880'
    ENV['REPLICATED_INTEGRATIONAPI'] = replicated_endpoint
    Travis.config.replicated.endpoint = ENV['REPLICATED_INTEGRATIONAPI']
  end

  describe 'with a valid enterprise license' do
    before do
      stub_request(:get, license_url)
        .to_return(body: MultiJson.dump({
          'fields' => [{
            "field" => "te_license",
            "value" => "---\nproduction:\n  license:\n    hostname: foo.example.com\n    expires: '2020-08-18'\n    seats: 20\n    queue:\n      limit: 999999\n    signature: !binary |-\n      xxxxxxxxxxxxxxxxx==\n"
          }],
          'expiration_time' => 1.month.from_now.iso8601
        }), headers: { 'Content-Type' => 'application/json' })
    end

    it 'accepts the request' do
      expect(body).to be_truthy
    end
  end

  describe 'with a seat exceed enterprise license' do
    before do
      stub_request(:get, license_url)
        .to_return(body: MultiJson.dump({
          'fields' => [{
            "field" => "te_license",
            "value" => "---\nproduction:\n  license:\n    hostname: foo.example.com\n    expires: '2020-08-18'\n    seats: -1\n    queue:\n      limit: 999999\n    signature: !binary |-\n      xxxxxxxxxxxxxxxxx==\n"
          }],
          'expiration_time' => 1.month.from_now.iso8601
        }), headers: { 'Content-Type' => 'application/json' })
    end

    it 'rejects the request' do
      expect(body).to be_falsy
    end

    it 'logs rejected' do
        body
        expect(log).to match /Enterprise account travis-ci has exceeded seats./
    end
  end

  describe 'no REPLICATED_INTEGRATIONAPI' do
    before do
        ENV.delete('REPLICATED_INTEGRATIONAPI')
        Travis.config.replicated.endpoint = nil
        stub_request(:get, license_url)
          .to_return(body: MultiJson.dump({
            'fields' => [{
              "field" => "te_license",
              "value" => "---\nproduction:\n  license:\n    hostname: foo.example.com\n    expires: '2020-08-18'\n    seats: 20\n    queue:\n      limit: 999999\n    signature: !binary |-\n      xxxxxxxxxxxxxxxxx==\n"
            }],
            'expiration_time' => 1.month.from_now.iso8601
          }), headers: { 'Content-Type' => 'application/json' })
    end

    it 'rejects the request' do
        expect(body).to be_falsy
    end

    it 'logs rejected' do
        body
        expect(log).to match /Replicated License API endpoint not found./
    end
  end
end