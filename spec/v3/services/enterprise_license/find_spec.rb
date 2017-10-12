describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }

  before do
    replicated_endpoint = 'https://10.169.183.13:9880'
    ENV['REPLICATED_INTEGRATIONAPI'] = replicated_endpoint
    stub_request(:get, "#{replicated_endpoint}/license/v1/license")
      .to_return(body: File.read('spec/support/enterprise_license.json'), headers: { 'Content-Type' => 'application/json' })
  end

  describe "fetching enterprise license" do
    before     { get("/v3/enterprise_license") }
    example    { expect(last_response.status).to eq 200 }
    example    {
      expect(parsed_body).to be == {
        "seats" => 20,
        "active_users" => 1
      }
    }
  end
end