describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:user2) { Travis::API::V3::Models::User.find_by_login('josevalim') }


  before do
    ENV['REPLICATED_LICENSELICENSEID'] = "12345675ad"
    ENV['REPLICATED_LICENSECHANNELNAME'] = "trial"
    ENV['REPLICATED_LICENSEEXPIRATIONDATE'] = "2018-08-18T00:00:00Z"
    ENV['REPLICATED_CUSTOMLICENSE'] = "---\nproduction:\n  license:\n    hostname: foo.example.com\n    expires: '2018-08-18'\n    seats: 20\n    queue:\n      limit: 999999\n    signature: !binary |-\n      xxxxxxxxxxxxxxxxx==\n"
  end

  describe "with REPLICATED_LICENSELICENSEID" do
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

  describe "no REPLICATED_LICENSELICENSEID" do
    before { ENV.delete('REPLICATED_LICENSELICENSEID') }

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