describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }

  before do
    Redis.new.set("t:1", nil)   
    replicated_endpoint = 'https://fake.fakeserver.com:9880'
    ENV['REPLICATED_INTEGRATIONAPI'] = replicated_endpoint
    stub_request(:get, "#{replicated_endpoint}/license/v1/license")
      .to_return(body: File.read('spec/support/enterprise_license.json'), headers: { 'Content-Type' => 'application/json' })
  end

  describe "fetching enterprise license" do
    before     { get("/v3/enterprise_license") }
    example    { expect(last_response.status).to eq 200 }
    example    {
      expect(parsed_body).to be == {
        "license_id" => "12345675ad",
        "license_type" => "trial",
        "seats" => 20,
        "active_users" => 1,
        "expiration_time" => "2018-08-18T00:00:00Z"
      }
    }
  end

  describe "no REPLICATED_INTEGRATIONAPI" do
    before { ENV.delete('REPLICATED_INTEGRATIONAPI') }

    describe "fetching enterprise license" do
      before     { get("/v3/enterprise_license") }
      example    { expect(last_response.status).to eq 403 }
      example    {
        expect(parsed_body).to be == {
          "@type"        => "error",
          "error_type"   =>"insufficient_access",
          "error_message"=>"forbidden"
        }
      }
    end
  end
end