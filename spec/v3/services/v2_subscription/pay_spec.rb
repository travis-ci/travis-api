describe Travis::API::V3::Services::V2Subscription::Pay, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:organization) {Travis::API::V3::Models::Organization.create() }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/v2_subscription/123/pay', nil)

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request) do
      stub_billing_request(:post, "/v2/subscriptions/#{subscription_id}/pay", auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: JSON.generate(billing_v2_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id })), headers: {'Content-Type' => 'application/json'})
    end

    it 'pays the subscription' do
      post("/v3/v2_subscription/#{subscription_id}/pay", nil, headers)

      expect(last_response.status).to eq(200)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
