describe Travis::API::V3::Services::Subscription::Cancel, set_app: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/subscription/123/cancel')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { Factory(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:client) { stub(:billing_client) }
    let(:subscription_id) { rand(999) }

    before do
      Travis::API::V3::BillingClient.stubs(:new).with(user.id).returns(client)
    end

    it 'updates the address' do
      client.expects(:cancel_subscription).with(subscription_id.to_s)

      post("/v3/subscription/#{subscription_id}/cancel", nil, headers)

      expect(last_response.status).to eq(202)
    end
  end
end
