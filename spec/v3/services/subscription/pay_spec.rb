describe Travis::API::V3::Services::Subscription::Pay, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:organization) { FactoryBot.create(:org, login: 'travis') }

  let(:org_authorization) { { 'permissions' => ['account_billing_view','account_billing_update','account_plan_create','account_plan_view','account_plan_usage','account_plan_invoices','account_settings_create','account_settings_delete'] } }
  before { stub_request(:get, %r((.+)/permissions/org/(.+))).to_return(status: 200, body: JSON.generate(org_authorization)) }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/subscription/123/pay', nil)

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
      stub_billing_request(:post, "/subscriptions/#{subscription_id}/pay", auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: JSON.dump(billing_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id })))
    end

    it 'pays the subscription' do
      post("/v3/subscription/#{subscription_id}/pay", nil, headers)

      expect(last_response.status).to eq(200)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
