describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:user2) { Travis::API::V3::Models::User.find_by_login('josevalim') }


  before do
    replicated_endpoint = 'https://fake.fakeserver.com:9880'
    ENV['REPLICATED_INTEGRATIONAPI'] = replicated_endpoint
    stub_request(:get, "#{replicated_endpoint}/license/v1/license")
      .to_return(body: File.read('spec/support/enterprise_license.json'), headers: { 'Content-Type' => 'application/json' })
  end

  describe "with REPLICATED_INTEGRATIONAPI" do
    before { user.update_attribute(:github_oauth_token, nil) }
    before { user2.update_attribute(:suspended, false) }

    describe "fetching enterprise license" do
      before     { get("/v3/enterprise_license") }
      example    { expect(last_response.status).to eq 200 }
      example    {
        expect(parsed_body).to be == {
          "license_id" => "12345675ad",
          "license_type" => "trial",
          "seats" => 20,
          "active_users" => 3,
          "expiration_time" => "2018-08-18T00:00:00Z"
        }
      }
    end
  end

  describe "no REPLICATED_INTEGRATIONAPI" do
    before { ENV.delete('REPLICATED_INTEGRATIONAPI') }

    describe "fetching enterprise license" do
      before     { get("/v3/enterprise_license") }
      example    { expect(last_response.status).to eq 403 }
      example    {
        expect(parsed_body).to be == {
          "@type"        => "error",
          "error_type"   => "insufficient_access",
          "error_message"=> "forbidden"
        }
      }
    end
  end
end