describe Travis::API::V3::Services::Subscription::UpdateAddress, set_app: true do
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
    let(:user) { Factory(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:address_data) { { "address" => "Rigaer Strasse" } }
    let(:client) { stub(:billing_client) }
    let(:subscription_id) { rand(999) }

    before do
      Travis::API::V3::Billing.stubs(:new).with(user.id).returns(client)
    end

    it 'updates the address' do
      client.expects(:update_address).with(subscription_id.to_s, address_data)

      patch("/v3/subscription/#{subscription_id}/address", JSON.generate(address_data), headers)

      expect(last_response.status).to eq(202)
    end
  end
end
