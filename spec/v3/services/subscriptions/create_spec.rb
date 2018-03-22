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
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:subscription_data) {{ 'address'=> 'Rigaer' }}
    let(:client) { stub(:billing_client) }
    let(:subscription) { Travis::API::V3::Models::Subscription.new(billing_response_body('id' => 1234))}

    before do
      Travis::API::V3::BillingClient.stubs(:new).with(user.id).returns(client)
    end

    it 'Creates the subscription and responds with its representation' do
      client.expects(:create_subscription).with(subscription_data).returns(subscription)

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
          'first_name' => 'ana',
          'last_name' => 'rosas',
          'company' => '',
          'billing_email' => 'a.rosas10@gmail.com',
          'zip_code' => '28450',
          'address' => 'Luis Spota',
          'address2' => '',
          'city' => 'Comala',
          'state' => nil,
          'country' => 'Mexico'
        },
        'credit_card_info' => {
          'card_owner' => 'ana',
          'last_digits' => '4242',
          'expiration_date' => '9/2021'
        },
        'owner'=> {
          'type' => 'Organization',
          'id' => 43
        }
      })
    end
  end
end
