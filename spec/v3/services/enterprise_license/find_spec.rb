require 'pry'
describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }

  before do
    stub_request(:get, "http://localhost:8800/license.json")
      .to_return(body: File.read('spec/support/enterprise_license.json'), headers: { 'Content-Type' => 'application/json' })
  end

  describe "fetching enterprise license" do
    before     { get("/v3/enterprise_license") }
    example    { expect(last_response.status).to eq 200 }
    example    {
      expect(parsed_body).to be == {
        "seats" => 20
      }
    }
  end
end