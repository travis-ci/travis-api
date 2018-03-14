describe Travis::API::V3::Services::Subscriptions::All, set_app: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/subscriptions')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { Factory(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:client) { stub(:billing_client) }
    let(:subscriptions) { [Travis::API::V3::Billing::Subscription.new('id' => 1234)]}

    before do
      Travis::API::V3::Billing.stubs(:new).with(user.id).returns(client)
    end

    it 'responds with list of subscriptions' do
      client.stubs(:all).returns(subscriptions)

      get('/v3/subscriptions', {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'subscriptions',
        '@representation' => 'standard',
        '@href' => '/v3/subscriptions',
        'subscriptions' => [{
          'id' => 1234
        }]
      })
    end
  end
end
