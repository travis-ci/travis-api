describe Travis::API::V3::Services::V2Subscription::Share, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:receiver) { FactoryBot.create(:org) }
  let(:data) { {'plan'=> subscription_id, 'receiver_id' => receiver.id } }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403 for post' do
      post('/v3/v2_subscription/123/share', {})

      expect(last_response.status).to eq(403)
    end

    it 'responds 403 for delete' do
      delete('/v3/v2_subscription/123/share', {})

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated create share' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request) do
      stub_billing_request(:post, "/v2/subscriptions/#{subscription_id}/share", auth_key: billing_auth_key, user_id: user.id)
        .with(body: {
          'plan' => subscription_id.to_s,
          'receiver' => receiver.id,
          'requested_by' => user.id
        })
        .to_return(status: 204)
    end

    it 'shares the subscription' do
      post("/v3/v2_subscription/#{subscription_id}/share", JSON.generate(data), headers)

      expect(last_response.status).to eq(204)
      expect(stubbed_request).to have_been_made.once
    end
  end

  context 'authenticated delete share' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request) do
      stub_request(:delete, "#{billing_url}/v2/subscriptions/#{subscription_id}/share?plan=#{subscription_id}&receiver=#{receiver.id}&requested_by=#{user.id}").with(
          headers: {
            'X-Travis-User-Id' => user.id
          }
        )
        .to_return(status: 204)
    end

    it 'deletes subscription share' do
      delete("/v3/v2_subscription/#{subscription_id}/share", JSON.generate(data), headers)
      expect(last_response.status).to eq(204)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
