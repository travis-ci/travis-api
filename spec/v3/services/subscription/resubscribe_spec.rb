describe Travis::API::V3::Services::Subscription::Resubscribe, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch('/v3/subscription/123/resubscribe')

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
      stub_billing_request(:patch, "/subscriptions/#{subscription_id}/resubscribe", auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.generate(billing_subscription_response_body(
          owner: { type: 'User', id: user.id },
          status: 'incomplete',
          client_secret: 'ABC'
        )))
    end

    it 'resubscribes the subscription' do
      patch("/v3/subscription/#{subscription_id}/resubscribe", nil, headers)

      expect(last_response.status).to eq(201)
      expect(stubbed_request).to have_been_made.once
      expect(parsed_body['status']).to eq('incomplete')
      expect(parsed_body['client_secret']).to eq('ABC')
    end
  end
end
