describe Travis::API::V3::Services::V2Subscriptions::Create, set_app: true, billing_spec_helper: true do
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
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}",
                     'Content-Type' => 'application/json' }}
    let(:subscription_data) do
      {
        'plan' => 'pro_tier_plan',
        'client_secret' => 'client_secret',
        'organization_id' => organization.id,
        'billing_info.first_name' => 'Travis',
        'billing_info.last_name' => 'Schmidt',
        'billing_info.company' => 'Travis',
        'billing_info.address' => 'Rigaer Strasse',
        'billing_info.city' => 'Berlin',
        'billing_info.country' => 'Germany',
        'billing_info.zip_code' => '10001',
        'billing_info.billing_email' => 'travis@example.org',
        'billing_info.state' => 'Alabama',
        'billing_info.has_local_registration' => true,
        'credit_card_info.token' => 'token_from_stripe'
      }
    end

    context 'billing app returns a successful response' do
      let!(:stubbed_request) do
        stub_billing_request(:post, '/v2/subscriptions', auth_key: billing_auth_key, user_id: user.id)
          .with(body: {
            'plan' => 'pro_tier_plan',
            'client_secret' => 'client_secret',
            'coupon' => nil,
            'organization_id' => organization.id.to_s,
            'billing_info' => {
              'first_name' => 'Travis',
              'last_name' => 'Schmidt',
              'company' => 'Travis',
              'address' => 'Rigaer Strasse',
              'city' => 'Berlin',
              'country' => 'Germany',
              'zip_code' => '10001',
              'billing_email' => 'travis@example.org',
              'state' => 'Alabama',
              'has_local_registration' => 'true'
            },
            'credit_card_info' => {
              'token' => 'token_from_stripe'
            },
            'v1_subscription_id': nil
          })
          .to_return(status: 201, body: JSON.generate(billing_subscription_response_body(
            'id' => 1234,
            'owner' => { 'type' => 'Organization', 'id' => organization.id },
            'canceled_at': nil,
            'valid_to': nil,
            'status': nil,
            'scheduled_plan': nil,
            'plan_config' => {
              'id' => 'pro_tier_plan',
              'name' => 'Pro Tier Plan',
              'plan_type' => 'metered',
              'concurrency_limit' => 20,
              'private_repos' => true,
              'starting_price' => 30_000,
              'starting_users' => 10_000,
              'private_credits' => 500_000,
              'public_credits' => 40_000,
              'annual' => false,
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
              'trial_plan': false,
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
            'addons' => [{
              'id': 7,
              'plan_id': 3,
              "name": "OSS Build Credits",
              'addon_config_id': 'oss_tier_credits',
              'type': 'credit_public',
              'created_at': '2017-11-28T00:09:59.502Z',
              'updated_at': '2017-11-28T00:09:59.502Z',
              'current_usage_id': 7,
              'current_usage': {
                'id': 7,
                'addon_id': 7,
                'addon_quantity': 40_000,
                'addon_usage': 0,
                'remaining': 40_000,
                'purchase_date': '2017-11-28T00:09:59.502Z',
                'valid_to': '2017-11-28T00:09:59.502Z',
                'status': 'pending',
                'active': false,
                'created_at': '2017-11-28T00:09:59.502Z',
                'updated_at': '2017-11-28T00:09:59.502Z'
              }
            }],
            'discount' => nil,
            'client_secret' => 'client_secret',
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
              'has_local_registration' => true,
            },
            'credit_card_info' => {
              'card_owner' => 'Travis Schmidt',
              'expiration_date' => '11/21',
              'last_digits' => '1111'
            })))
      end

      it 'creates the subscription and responds with its representation' do
        post('/v3/v2_subscriptions', subscription_data, headers)

        expect(last_response.status).to eq(201)
        expect(parsed_body).to eql_json({
          '@type' => 'v2_subscription',
          '@representation' => 'standard',
          'id' => 1234,
          'created_at' => '2017-11-28T00:09:59.502Z',
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
            'private_repos' => true,
            'starting_users' => 10_000,
            'starting_price' => 30_000,
            'private_credits' => 500_000,
            'public_credits' => 40_000,
            'concurrency_limit' => 20,
            'plan_type' => 'metered',
             'vm_size' => nil,
            'trial_config' => nil,
            'annual' => false,
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
          'addons' => [{
            '@type' => 'v2_addon',
            '@representation' => 'minimal',
            'id' => 7,
            'name' => 'OSS Build Credits',
            'type' => 'credit_public',
            'recurring' => nil,
            'current_usage' => {
              '@type' => 'v2_addon_usage',
              '@representation' => 'standard',
              'id' => 7,
              'addon_id' => 7,
              'addon_quantity' => 40_000,
              'addon_usage' => 0,
              'purchase_date' => '2017-11-28T00:09:59.502Z',
              'valid_to' => '2017-11-28T00:09:59.502Z',
              'remaining' => 40_000,
              'status' => 'pending',
              'active' => false
            }
          }],
          'client_secret' => 'client_secret',
          'source' => 'stripe',
          'billing_info' => {
            '@type' => 'v2_billing_info',
            '@representation' => 'standard',
            'id' => 1234,
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
            'vat_id' => nil,
            'has_local_registration' => true,
          },
          'credit_card_info' => {
            'id' => 1234,
            '@type' => 'v2_credit_card_info',
            '@representation' => 'standard',
            'card_owner' => 'Travis Schmidt',
            'last_digits' => '1111',
            'expiration_date' => '11/21'
          },
          'owner' => {
            '@type' => 'organization',
            '@representation' => 'minimal',
            '@href' => "/v3/org/#{organization.id}",
            'id' => organization.id,
            'vcs_type' => organization.vcs_type,
            'name' => organization.name,
            'login' => 'travis',
            'ro_mode' => true
          },
          'payment_intent' => nil,
        })
        expect(stubbed_request).to have_been_made.once
      end
    end

    context 'billing app returns an error' do
      let!(:stubbed_request) do
        stub_billing_request(:post, '/v2/subscriptions', auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 422, body: JSON.generate(error: 'This is the error message from the billing app'))
      end

      it 'responds with the same error' do
        post('/v3/v2_subscriptions', JSON.generate(subscription_data), headers)

        expect(last_response.status).to eq(422)
        expect(parsed_body).to eql_json('@type' => 'error',
         'error_type' => 'unprocessable_entity', 'error_message' => 'This is the error message from the billing app')
      end
    end
  end
end
