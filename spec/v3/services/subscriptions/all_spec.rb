describe Travis::API::V3::Services::Subscriptions::All, set_app: true, billing_spec_helper: true do
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
    let(:organization) { Factory(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:plan) do
      {
        '@type' => 'plan',
        '@representation' => 'standard',
        'id' => 'travis-ci-ten-builds',
        'name' => 'Startup',
        'builds' => 10,
        'price' => 12500,
        'currency' => 'USD',
        'annual' => false
      }
    end

    let(:subscriptions_data) { [billing_subscription_response_body('id' => 1234, 'plan' => plan,'permissions' => { 'read' => true, 'write' => false }, 'owner' => { 'type' => 'Organization', 'id' => organization.id })] }

    let(:v2_response_body) { JSON.dump(subscriptions_data) }

    let(:expected_json) do
      {
        '@type' => 'subscriptions',
        '@representation' => 'standard',
        '@href' => '/v3/subscriptions',
        'subscriptions' => [{
          '@type' => 'subscription',
          '@representation' => 'standard',
          '@permissions' => { 'read' => true, 'write' => false },
          'id' => 1234,
          'valid_to' => '2017-11-28T00:09:59Z',
          'plan' => plan,
          'coupon' => '',
          'status' => 'canceled',
          'source' => 'stripe',
          'billing_info' => {
            '@type' => 'billing_info',
            '@representation' => 'standard',
            'id' => 1234,
            'first_name' => 'ana',
            'last_name' => 'rosas',
            'company' => '',
            'billing_email' => 'a.rosas10@gmail.com',
            'zip_code' => '28450',
            'address' => 'Luis Spota',
            'address2' => '',
            'city' => 'Comala',
            'state' => nil,
            'country' => 'Mexico',
            'vat_id' => '123456'
          },
          'credit_card_info' => {
            '@type' => 'credit_card_info',
            '@representation' => 'standard',
            'id' => 1234,
            'card_owner' => 'ana',
            'last_digits' => '4242',
            'expiration_date' => '9/2021'
          },
          'owner'=> {
            '@type' => 'organization',
            '@representation' => 'minimal',
            '@href' => "/v3/org/#{organization.id}",
            'id' => organization.id,
            'login' => 'travis'
          }
        }]
      }
    end

    before do
      stub_billing_request(:get, '/subscriptions', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: v2_response_body)
    end

    it 'responds with list of subscriptions' do
      get('/v3/subscriptions', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end

    context 'with subscription data nested under a `subscriptions` key' do
      let(:v2_response_body) { JSON.dump(subscriptions: subscriptions_data)}

      it 'responds with list of subscriptions' do
        get('/v3/subscriptions', {}, headers)
        expect(last_response.status).to eq(200)
        expect(parsed_body).to eql_json(expected_json)
      end
    end

    context 'with a null plan' do
      let(:plan) { nil }

      it 'responds with a null plan' do
        get('/v3/subscriptions', {}, headers)

        expect(last_response.status).to eq(200)
        expect(parsed_body['subscriptions'][0].fetch('plan')).to eq(nil)
      end
    end
  end
end
