describe Travis::API::V3::Services::Subscription::UpdateCreditcard, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch('/v3/subscription/123/creditcard', { })

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { Factory(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:creditcard_data) { { "cc_owner" => "Hans" } }
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request) do
      stub_billing_request(:patch, "/subscriptions/#{subscription_id}/creditcard", auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200)
        # TODO: check sent data
    end

    it 'updates the creditcard' do
      patch("/v3/subscription/#{subscription_id}/creditcard", JSON.generate(creditcard_data), headers)

      expect(last_response.status).to eq(202)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
