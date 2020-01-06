describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:user2) { Travis::API::V3::Models::User.find_by_login('josevalim') }


  before do
    ENV['REPLICATED_LICENSE_ID'] = "12345675ad"
    Travis.config.replicated.license_id = ENV['REPLICATED_LICENSE_ID']
    ENV['REPLICATED_LICENSE_CHANNEL_NAME'] = "trial"
    Travis.config.replicated.license_type = ENV['REPLICATED_LICENSE_CHANNEL_NAME']
    ENV['REPLICATED_LICENSE_EXPIRATION_DATE'] = "2018-08-18T00:00:00Z"
    Travis.config.replicated.expiration_time = ENV['REPLICATED_LICENSE_EXPIRATION_DATE']
    ENV['REPLICATED_CUSTOM_LICENSE'] = "---\nproduction:\n  license:\n    hostname: foo.example.com\n    expires: '2018-08-18'\n    seats: 20\n    queue:\n      limit: 999999\n    signature: !binary |-\n      xxxxxxxxxxxxxxxxx==\n"
    Travis.config.replicated.license_custom = ENV['REPLICATED_CUSTOM_LICENSE']
  end

  describe "with REPLICATED_LICENSE_ID" do
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
          "active_users" => 1,
          "expiration_time" => "2018-08-18T00:00:00Z"
        }
      }
    end
  end

  describe "no REPLICATED_LICENSE_ID" do
    before { ENV.delete('REPLICATED_LICENSE_ID') }

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