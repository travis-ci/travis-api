describe Travis::API::V3::Services::Subscription::UpdateAddress, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch('/v3/subscription/123/address', { })

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:address_data) { {
      "address" => "Rigaer Strasse",
      'first_name' => 'Travis',
      'last_name' => 'Schmidt',
      'company' => 'Travis',
      'city' => 'Berlin',
      'country' => 'Germany',
      'zip_code' => '10001',
      'billing_email' => 'travis@example.org',
      'has_local_registration' => true
      } }
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request) do
      stub_billing_request(:patch, "/subscriptions/#{subscription_id}/address", auth_key: billing_auth_key, user_id: user.id)
        .with(body: {
            'first_name' => 'Travis',
            'last_name' => 'Schmidt',
            'company' => 'Travis',
            'address' => 'Rigaer Strasse',
            'city' => 'Berlin',
            'country' => 'Germany',
            'zip_code' => '10001',
            'billing_email' => 'travis@example.org',
            'has_local_registration' => true
          })
        .to_return(status: 204)
    end

    it 'updates the address' do
      patch("/v3/subscription/#{subscription_id}/address", JSON.generate(address_data), headers)

      expect(last_response.status).to eq(204)
      expect(stubbed_request).to have_been_made.once
    end
  end
end
