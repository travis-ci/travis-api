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
        'starting_price': 30_000,
        'starting_users': 10_000,
        'private_credits': 500_000,
        'public_credits': 40_000,
        'trial_plan': false,
        'addon_configs' => {
          'free_tier_credits' => {
            'name' => 'Free 10 000 credits (renewed monthly)',
            'expires' => true,
            'expires_in' => 1,
            'renew_after_expiration' => true,
            'price' => 0,
            'price_id' => 'price_1234567890',
            'price_type' => 'fixed',
            'quantity' => 10_000,
            'standalone' => false,
            'type' => 'credit_private',
            'available_for_plans' => '%w[free_tier_plan]'
          },
          'oss_tier_credits' => {
            'name' => 'Free 40 000 credits (renewed monthly)',
            'expires' => true,
            'expires_in' => 1,
            'renew_after_expiration' => true,
            'price' => 0,
            'price_id' => 'price_0987654321',
            'price_type' => 'fixed',
            'quantity' => 40_000,
            'standalone' => false,
            'type' => 'credit_public',
            'private_repos' => false,
            'available_for_plans' => '%w[free_tier_plan standard_tier_plan pro_tier_plan]'
          }
        }
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
          'canceled_at' => nil,
          'status' => nil,
          'valid_to' => nil,
          'scheduled_plan_name' => nil,
          'cancellation_requested' => false,
          'current_trial' => nil,
          'defer_pause' => false,
          'plan' => {
            '@type' => 'v2_plan_config',
            '@representation' => 'standard',
            'id' => 'pro_tier_plan',
            'name' => 'Pro Tier Plan',
            'concurrency_limit' => 20,
            'plan_type' => 'metered',
            'private_repos' => true,
            'starting_price' => 30_000,
            'starting_users' => 10_000,
            'private_credits' => 500_000,
            'public_credits' => 40_000,
            'annual' => false,
            'vm_size' => nil,
            'trial_config' => nil,
            'auto_refill_thresholds' => [10000, 50000, 100000],
            'auto_refill_amounts' => [
              {
                'amount' => 25000,
                'price' => 1500
              },
              {
                'amount' => 100000,
                'price' => 6000
              },
              {
                'amount' => 200000,
                'price' => 6000
              },
              {
                'amount' => 400000,
                'price' => 12000
              }
            ],
            'trial_plan' => false,
            'available_standalone_addons' => [
              {
                'id' => 'credits_25k',
                'name' => '25 000 credits (2,5k Linux build minutes)',
                'price' => 1500,
                'quantity' => 25000,
                'type' => 'credit_private'
              },
              {
                'id' => 'credits_500k',
                'name' => '500 000 credits (50k Linux build minutes)',
                'price' => 30000,
                'quantity' => 500000,
                'type' => 'credit_private'
              }
            ],
            'addon_configs' => {
              'free_tier_credits' => {
                'name' => 'Free 10 000 credits (renewed monthly)',
                'expires' => true,
                'expires_in' => 1,
                'renew_after_expiration' => true,
                'price' => 0,
                'price_id' => 'price_1234567890',
                'price_type' => 'fixed',
                'quantity' => 10_000,
                'standalone' => false,
                'type' => 'credit_private',
                'available_for_plans' => '%w[free_tier_plan]'
              },
              'oss_tier_credits' => {
                'name' => 'Free 40 000 credits (renewed monthly)',
                'expires' => true,
                'expires_in' => 1,
                'renew_after_expiration' => true,
                'price' => 0,
                'price_id' => 'price_0987654321',
                'price_type' => 'fixed',
                'quantity' => 40_000,
                'standalone' => false,
                'type' => 'credit_public',
                'private_repos' => false,
                'available_for_plans' => '%w[free_tier_plan standard_tier_plan pro_tier_plan]'
              }
            }
          },
          'auto_refill' => {
            '@type' => 'auto_refill',
            '@representation' => 'minimal',
            'addon_id' => nil,
            'enabled' => nil,
            'threshold' => 25000,
            'amount' => 10000
          },
          'addons' => [
            {
              '@type' => 'v2_addon',
              '@representation' => 'minimal',
              'id' => '1',
              'name' => 'OSS Build Credits',
              'type' => 'credit_public',
              'recurring' => false,
              'current_usage' => {
                '@type' => 'v2_addon_usage',
                '@representation' => 'standard',
                'id' => 1,
                'addon_id' => 1,
                'addon_quantity' => 40_000,
                'addon_usage' => 0,
                'remaining' => 40_000,
                'purchase_date' => '2017-11-28T00:09:59.502Z',
                'valid_to' => '2017-12-28T00:09:59.502Z',
                'status' => 'subscribed',
                'active' => true
              }
            },
            {
              '@type' => 'v2_addon',
              '@representation' => 'minimal',
              'id' => 2,
              'name' => 'Build Credits',
              'type' => 'credit_private',
              'recurring' => false,
              'current_usage' =>
              {
                '@type' => 'v2_addon_usage',
                '@representation' => 'standard',
                'id' => 2,
                'addon_id' => 2,
                'addon_quantity' => 10_000,
                'addon_usage' => 0,
                'remaining' => 10_000,
                'purchase_date' => '2017-11-28T00:09:59.502Z',
                'valid_to' => '',
                'status' => 'subscribed',
                'active' => true
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
            'login' => 'travis',
            'name' => organization.name,
            'ro_mode' => true
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
            'zip_code' => '28450',
            'has_local_registration' => false,
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
