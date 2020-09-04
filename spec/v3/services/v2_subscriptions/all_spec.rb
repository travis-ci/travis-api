describe Travis::API::V3::Services::V2Subscriptions::All, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/v2_subscriptions')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:organization) { FactoryBot.create(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:plan) do
      {
        '@type': 'v2_plan_config',
        '@representation': 'standard',
        'id': 'pro_tier_plan',
        'name': 'Pro Tier Plan',
        'private_repos': true,
        'default_addons': [
          {
            'id': 'oss_tier_credits',
            'name': 'Free 40 000 credits (renewed monthly)',
            'price': 0,
            'quantity': 40_000,
            'type': 'credit_public'
          },
          {
            'id': 'credits_500k',
            'name': '500 000 credits (50k Linux build minutes)',
            'price': 30_000,
            'quantity': 500_000,
            'type': 'credit_private'
          },
          {
            'id': 'users_pro',
            'name': 'Pro Tier user licenses',
            'price': 0,
            'quantity': 10_000,
            'type': 'user_license'
          }
        ],
        'starting_price': 30_000,
        'starting_users': 10_000,
        'private_credits': 500_000,
        'public_credits': 40_000
      }
    end

    let(:subscriptions_data) { [billing_v2_subscription_response_body('id' => 1234, 'client_secret' => 'client_secret', 'plan_config' => plan, 'permissions' => { 'read' => true, 'write' => false }, 'owner' => { 'type' => 'Organization', 'id' => organization.id })] }
    let(:permissions_data) { [{'owner' => {'type' => 'Organization', 'id' => 1}, 'create' => true}] }

    let(:v2_response_body) { JSON.dump(plans: subscriptions_data, permissions: permissions_data) }

    let(:expected_json) do
      {
        '@type' => 'v2_subscriptions',
        '@representation' => 'standard',
        '@href' => '/v3/v2_subscriptions',
        '@permissions' => permissions_data,
        'v2_subscriptions' => [{
          '@type' => 'v2_subscription',
          '@representation' => 'standard',
          'id' => 1234,
          'plan' => {
            '@type' => 'v2_plan_config',
            '@representation' => 'standard',
            'id' => 'pro_tier_plan',
            'name' => 'Pro Tier Plan',
            'private_repos' => true,
            'default_addons' => [
              {
                'id' => 'oss_tier_credits',
                'name' => 'Free 40 000 credits (renewed monthly)',
                'price' => 0,
                'quantity' => 40_000,
                'type' => 'credit_public'
              },
              {
                'id' => 'credits_500k',
                'name' => '500 000 credits (50k Linux build minutes)',
                'price' => 30_000,
                'quantity' => 500_000,
                'type' => 'credit_private'
              },
              {
                'id' => 'users_pro',
                'name' => 'Pro Tier user licenses',
                'price' => 0,
                'quantity' => 10_000,
                'type' => 'user_license'
              }
            ],
            'starting_price' => 30_000,
            'starting_users' => 10_000,
            'private_credits' => 500_000,
            'public_credits' => 40_000
          },
          'addons' => [
            {
              'id' => '1',
              'plan_id' => '1',
              'name' => 'OSS Build Credits',
              'addon_type' => 'credit_public',
              'created_at' => '2020-07-09T12:06:13.293Z',
              'updated_at' => '2020-07-09T12:07:03.619Z',
              'current_usage_id' => 1,
              'current_usage' => {
                'id' => 1,
                'addon_id' => 1,
                'addon_quantity' => 10_000,
                'addon_usage' => 0,
                'purchase_date' => '2020-07-09T12:06:27.919Z',
                'valid_to' => nil,
                'status' => 'active',
                'created_at' => '2020-07-09T12:06:27.944Z',
                'updated_at' => '2020-07-09T12:06:27.944Z'
              }
            },
            {
              'id' => 2,
              'plan_id' => 1,
              'name' => 'Build Credits',
              'addon_type' => 'credit_private',
              'created_at' => '2020-07-09T12:06:17.003Z',
              'updated_at' => '2020-07-09T12:07:09.067Z',
              'current_usage_id' => 2,
              'current_usage' =>
              {
                'id' => 2,
                'addon_id' => 2,
                'addon_quantity' => 10_000,
                'addon_usage' => 0,
                'purchase_date' => '2020-07-09T12:06:31.739Z',
                'valid_to' => nil,
                'status' => 'active',
                'created_at' => '2020-07-09T12:06:31.741Z',
                'updated_at' => '2020-07-09T12:06:31.741Z'
              }
            }
          ],
          'source' => 'stripe',
          'owner' => {
            '@type' => 'organization',
            '@href' => "/v3/org/#{organization.id}",
            '@representation' => 'minimal',
            'id' => organization.id,
            'vcs_type' => organization.vcs_type,
            'login' => 'travis'
          },
          'billing_info' => {
            '@type' => 'v2_billing_info',
            '@representation' => 'standard',
            'id' => 1234,
            'address' => 'Luis Spota',
            'address2' => '',
            'billing_email' => 'a.rosas10@gmail.com',
            'city' => 'Comala',
            'company' => '',
            'country' => 'Mexico',
            'first_name' => 'ana',
            'last_name' => 'rosas',
            'state' => nil,
            'vat_id' => '123456',
            'zip_code' => '28450'
          },
          'credit_card_info' => {
            '@type' => 'v2_credit_card_info',
            '@representation' => 'standard',
            'id' => 1234,
            'card_owner' => 'ana',
            'expiration_date' => '9/2021',
            'last_digits' => '4242'
          },
          'client_secret' => 'client_secret',
          'payment_intent' => nil,
          'created_at' => '2017-11-28T00:09:59.502Z'
        }]
      }
    end

    before do
      stub_billing_request(:get, '/v2/subscriptions', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: v2_response_body)
    end

    it 'responds with list of subscriptions' do
      get('/v3/v2_subscriptions', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end

    context 'with a null plan' do
      let(:plan) { nil }

      it 'responds with a null plan' do
        get('/v3/v2_subscriptions', {}, headers)

        expect(last_response.status).to eq(200)
        expect(parsed_body['v2_subscriptions'][0].fetch('plan')).to eq(nil)
      end
    end
  end
end
