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
    let(:subscription_data) do
      {
        'plan' => 'travis-ci-ten-builds',
        'organization_id' => organization.id,
        'billing_info.first_name' => 'Travis',
        'billing_info.last_name' => 'Schmidt',
        'billing_info.company' => 'Travis',
        'billing_info.address' => 'Rigaer Strasse',
        'billing_info.city' => 'Berlin',
        'billing_info.country' => 'Germany',
        'billing_info.zip_code' => '10001',
        'billing_info.billing_email' => 'travis@example.org',
        'credit_card_info.card_owner' => 'Travis Schmidt',
        'credit_card_info.expiration_date' => '11/21',
        'credit_card_info.last_digits' => '1111',
      }
    end

    context 'billing app returns a successful response' do
      let!(:stubbed_request) do
        stub_billing_request(:post, '/subscriptions', auth_key: billing_auth_key, user_id: user.id)
          .with(body: {
            'organization_id' => organization.id,
            'plan' => 'travis-ci-ten-builds',
            'coupon' => nil,
            'billing_info' => {
              'first_name' => 'Travis',
              'last_name' => 'Schmidt',
              'company' => 'Travis',
              'address' => 'Rigaer Strasse',
              'city' => 'Berlin',
              'country' => 'Germany',
              'zip_code' => '10001',
              'billing_email' => 'travis@example.org',
            },
            'credit_card_info' => {
              'card_owner' => 'Travis Schmidt',
              'expiration_date' => '11/21',
              'last_digits' => '1111'
            }})
          .to_return(status: 201, body: JSON.dump(billing_response_body(
            'id' => 1234,
            'owner' => { 'type' => 'Organization', 'id' => organization.id },
            'plan' => 'travis-ci-ten-builds',
            'billing_info' => {
              'first_name' => 'Travis',
              'last_name' => 'Schmidt',
              'company' => 'Travis',
              'address' => 'Rigaer Strasse',
              'address2' => nil,
              'city' => 'Berlin',
              'state' => nil,
              'country' => 'Germany',
              'vat_id' => nil,
              'zip_code' => '10001',
              'billing_email' => 'travis@example.org',
            },
            'credit_card_info' => {
              'card_owner' => 'Travis Schmidt',
              'expiration_date' => '11/21',
              'last_digits' => '1111'
            })))
      end

      it 'Creates the subscription and responds with its representation' do
        post('/v3/subscriptions', JSON.dump(subscription_data), headers)

        expect(last_response.status).to eq(201)
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
            'first_name' => 'Travis',
            'last_name' => 'Schmidt',
            'company' => 'Travis',
            'billing_email' => 'travis@example.org',
            'zip_code' => '10001',
            'address' => 'Rigaer Strasse',
            'address2' => nil,
            'city' => 'Berlin',
            'state' => nil,
            'country' => 'Germany',
            'vat_id' => nil
          },
          'credit_card_info' => {
            '@type' => 'credit_card_info',
            '@representation' => 'minimal',
            'card_owner' => 'Travis Schmidt',
            'last_digits' => '1111',
            'expiration_date' => '11/21'
          },
          'owner' => {
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

    context 'billing app returns an error' do
      let!(:stubbed_request) do
        stub_billing_request(:post, '/subscriptions', auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 422, body: JSON.dump(error: 'This is the error message from the billing app'))
      end

      it 'responds with the same error' do
        post('/v3/subscriptions', JSON.dump(subscription_data), headers)

        expect(last_response.status).to eq(422)
        expect(parsed_body).to eql_json("@type" => "error",
         "error_type" => "unprocessable_entity", 'error_message' => 'This is the error message from the billing app')
      end
    end
  end
end
