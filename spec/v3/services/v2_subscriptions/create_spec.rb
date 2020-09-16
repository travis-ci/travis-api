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
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
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
            'organization_id' => organization.id,
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
              'token' => 'token_from_stripe'
            }})
          .to_return(status: 201, body: JSON.dump(billing_subscription_response_body(
            'id' => 1234,
            'owner' => { 'type' => 'Organization', 'id' => organization.id },
            'plan_config' => {
              'id' => 'pro_tier_plan',
              'name' => 'Pro Tier Plan',
              'private_repos' => true,
              'starting_price' => 30_000,
              'starting_users' => 10_000,
              'private_credits' => 500_000,
              'public_credits' => 40_000,
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
            },
            'credit_card_info' => {
              'card_owner' => 'Travis Schmidt',
              'expiration_date' => '11/21',
              'last_digits' => '1111'
            })))
      end

      it 'Creates the subscription and responds with its representation' do
        post('/v3/v2_subscriptions', JSON.dump(subscription_data), headers)

        expect(last_response.status).to eq(201)
        expect(parsed_body).to eql_json({
          '@type' => 'v2_subscription',
          '@representation' => 'standard',
          'id' => 1234,
          'created_at' => '2017-11-28T00:09:59.502Z',
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
            '@type' => 'v2_addon',
            '@representation' => 'minimal',
            'id' => 7,
            'name' => 'OSS Build Credits',
            'type' => 'credit_public',
            'current_usage' => {
              '@type' => 'v2_addon_usage',
              '@representation' => 'standard',
              'id' => 7,
              'addon_id' => 7,
              'addon_quantity' => 40000,
              'addon_usage' => 0,
              'remaining' => 40000,
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
            'vat_id' => nil
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
            'login' => 'travis',
            'allowance' => {
              "@type" => "allowance",
              "@representation" => "minimal",
              "subscription_type" => 1,
              "public_repos" => true,
              "private_repos" => false,
              "concurrency_limit" => 1
            }
          },
          'payment_intent' => nil,
        })
        expect(stubbed_request).to have_been_made.once
      end
    end

    context 'billing app returns an error' do
      let!(:stubbed_request) do
        stub_billing_request(:post, '/v2/subscriptions', auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 422, body: JSON.dump(error: 'This is the error message from the billing app'))
      end

      it 'responds with the same error' do
        post('/v3/v2_subscriptions', JSON.dump(subscription_data), headers)

        expect(last_response.status).to eq(422)
        expect(parsed_body).to eql_json('@type' => 'error',
         'error_type' => 'unprocessable_entity', 'error_message' => 'This is the error message from the billing app')
      end
    end
  end
end
