describe Travis::API::V3::Services::EnterpriseLicense::Find, set_app: true do
  let(:parsed_body) { JSON.load(body) }

  before do

    user = Factory(:user, emails: [Email.new(email: "hello@example.com")])
    user1 = Factory(:user, emails: [Email.new(email: "hello2@example.com")])
    user2 = Factory(:user, emails: [Email.new(email: "hello3@example.com")])

    Factory(:commit, committer_email: user.emails.first.email)
    Factory(:commit, committer_email: user1.emails.first.email)
    Factory(:commit, committer_email: user2.emails.first.email)
    Factory(:commit, committer_email: user2.emails.first.email)
    Factory(:commit, committer_email: user2.emails.first.email)

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
        "active_users" => 3
      }
    }
  end
end