describe Travis::API::V3::Services::Subscription::Cancel, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:reason_data) { {"reason"=>"Other", "reason_details"=>"Cancellation details go here"} }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/subscription/123/cancel', { })

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
      stub_billing_request(:post, "/subscriptions/#{subscription_id}/cancel", auth_key: billing_auth_key, user_id: user.id)
        .with(body: reason_data)
        .to_return(status: 204)
    end

    it 'cancels the subscription' do
      post("/v3/subscription/#{subscription_id}/cancel", JSON.generate(reason_data), headers)

      expect(last_response.status).to eq(204)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
