describe Travis::API::V3::Services::Subscriptions::Create, set_app: true, billing_spec_helper: true do
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
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:subscription_data) {{ 'address'=> 'Rigaer' }}

    let!(:stubbed_request) do
      stub_billing_request(:post, '/subscriptions', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: JSON.dump(billing_response_body('id' => 1234, 'owner' => { 'type' => 'Organization', 'id' => organization.id })))
        # TODO: Check sent data
    end

    it 'Creates the subscription and responds with its representation' do
      post('/v3/subscriptions', JSON.dump(subscription_data), headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'subscription',
        '@representation' => 'standard',
        'id' => 1234,
        'valid_to' => '2017-11-28T00:09:59Z',
        'plan' => 'travis-ci-ten-builds',
        'coupon' => '',
        'status' => 'canceled',
        'source' => 'stripe',
        'billing_info' => {
          '@type' => 'billing_info',
          '@representation' => 'minimal',
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
          '@representation' => 'minimal',
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
      })
      expect(stubbed_request).to have_been_made.once
    end
  end
end
