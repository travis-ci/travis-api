describe Travis::API::V3::Models::V2Subscription do
  let(:user) { FactoryBot.create(:user) }
  let(:attributes) do
    {
      'id' => 'id',
      'permissions' => { 'read' => true, 'write' => true },
      'created_at' => Date.today.to_s,
      'status' => nil,
      'valid_to' => nil,
      'canceled_at' => nil,
      'scheduled_plan' => nil,
      'cancellation_requested' => false,
      'current_trial' => nil,
      'billing_info' => {
        'address' => 'Washington str.',
        'address2' => '',
        'billing_email' => 'john.doe@example.com',
        'city' => 'Washington',
        'company' => 'Travis CI',
        'country' => 'United States of America',
        'first_name' => 'John',
        'last_name' => 'Doe',
        'has_local_registration' => true,
        'state' => 'Alabama',
        'vat_id' => '',
        'zip_code' => '2001',
      },
      'plan_config' => {
        'id' => 'pro_tier_plan',
        'name' => 'Pro Tier Plan',
        'plan_type' => 'metered',
        'concurrency_limit' => 20,
        'private_repos' => true,
        'starting_price' => 30000,
        'starting_users' => 10000,
        'private_credits' => 500000,
        'public_credits' => 40000,
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
        'id' => 7,
        'name' => 'OSS Build Credits',
        'plan_id' => 3,
        'addon_config_id' => 'oss_tier_credits',
        'type' => 'credit_public',
        'created_at' => Date.today.to_s,
        'updated_at' => Date.today.to_s,
        'recurring' => false,
        'current_usage_id' => 7,
        'current_usage' => {
          'id' => 7,
          'addon_id' => 7,
          'addon_quantity' => 40_000,
          'addon_usage' => 0,
          'remaining' => 40_000,
          'purchase_date' => Date.today.to_s,
          'valid_to' => Date.today.to_s,
          'status' => 'pending',
          'active' => false,
          'created_at' => Date.today.to_s,
          'updated_at' => Date.today.to_s
        }
      }],
      'source' => 'stripe',
      'owner' => { 'id' => user.id, 'type' => 'User'},
      'client_secret' => 'secret',
      'payment_intent' => { 'status' => 'requires_action', 'client_secret' => 'abc', 'last_payment_error' => {} }
    }
  end

  subject { Travis::API::V3::Models::V2Subscription.new(attributes) }

  context 'basic fields' do
    it 'returns basic fields' do
      expect(subject.id).to eq(attributes['id'])
      expect(subject.plan).to be_a(Travis::API::V3::Models::V2PlanConfig)
      expect(subject.permissions).to be_a(Travis::API::V3::Models::BillingPermissions)
      expect(subject.owner).to be_a(Travis::API::V3::Models::User)
      expect(subject.payment_intent).to be_a(Travis::API::V3::Models::PaymentIntent)
      expect(subject.billing_info).to be_a(Travis::API::V3::Models::V2BillingInfo)
      expect(subject.billing_info.has_local_registration).to be true
    end
  end
end
